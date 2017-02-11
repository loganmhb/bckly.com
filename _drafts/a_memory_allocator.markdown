---
title: A Memory Allocator
layout: post
category: code
---

Though I work primarily as a web developer, I've been drawn to programming in C for years. I guess it's the antihero of programming languages: it's dangerous, yes, but it's at the center of everything. I'm thankful I don't have to write C for work, but there's a mystique to it that's appealing for hacking around in your spare time. You're close to the machine, the veil is pulled back, and there are no guard rails. You hear people talk about C in terms that are practically political: C is freedom. C is power. The most important project of the early Free Software Foundation was `gcc`, the GNU C compiler, because if you can compile C you can do whatever you need to do.

A week or two ago I happened upon a copy of _The C Programming Language_, by Dennis Ritchie and Brian Kernighan, the designers of the language and inventors of Unix. It's not the best book for learning secure, modern C, I'm sure, but it holds up quite well for someone just looking to tinker with something close to the machine, and there are magical moments reading it when concepts that seem impenetrable fall to a couple pages of clever code examples and I a sense of childlike delight -- moments which express what the !!con slogan memorably calls "the joy, excitement and surprise of programming."

One of these is a memory allocator -- an implementation of `malloc` and `free`, a fundamental tool of programming I'd treated so far as just another black box, assuming its implementation would be impenetrably complex. Hardened, performance-tuned memory allocators are not simple things, but it turns out you can write a basic, no-frills one in less than a hundred lines of code.

I set the K&R book aside for a few days, and having forgotten half of their example, I felt ready to implement my own.

My basic plan was to use a block of statically-allocated memory to avoid system calls, which are a project for another day (I think I need to read about `sbrk`?). I would store pointers to chunks of this memory in a linked list, handing them out via `malloc` and re-adding them to the list via `free`.

There were two key aspects of the design of K&R's memory allocator which I relied on. First, the information about a block's size is stored in a header which is just before the block itself.

When the user calls `free` on a pointer, you look immediately before that pointer to find the header storing the block's size, which keeps the user from having to pass the size manually to free. Second, the free list is sorted by memory address -- pointers with lower addresses first. This was not part of my original plan, but it's helpful when you're reclaiming chunks of memory because it makes it easy to tell when you have several adjacent chunks in a row on the free list that could be combined into a single, bigger chunk.

Once those two insights had settled in, the rest was basically pointer arithmetic, which was entirely new to me -- I've never written code that relies on finding something at a particular memory location *near* another pointer before, and it's tricky, but not as tricky as I feared. Here's the whole thing:

```c
#include <stdlib.h>
#include <stdio.h>

#define MEMSIZE 1048576

/*
 * Avoid any system memory considerations by using
 * statically-allocated memory. The free list will start as one block
 * pointing to this statically-allocated chunk.
 */
static char memory[MEMSIZE];

/* Header for a memory block.
 * 
 * `next` points to the header of the next block in the free list;
 * `size` indicates how much memory is allocated for this block. */
typedef struct header {
  struct header *next;
  unsigned size;
} header;

/* Pointer to the beginning of the free list. The free list is a
   series of `header`s, *sorted by memory address* (otherwise
   everything breaks). */
static header *free_list = NULL;


/* Size is in bytes. As an implementation detail it gets rounded up to
 * increments of sizeof(header) bytes, to simplify the pointer
 * arithmetic and bookkeeping. */
void *new_malloc(unsigned required_size) {
  while ((required_size % sizeof(header)) != 0) required_size++;

  /* Special case to initialize the free list. */
  if (free_list == NULL) {
    free_list = (header *)memory;
    free_list->size = MEMSIZE - sizeof(header);
    free_list->next = NULL;
  }

  /* Find the first big-enough block in the free list. */
  header *current = free_list;
  header *prev = NULL;
  while(current->size < required_size) {
    prev = current;
    current = current->next;
    if (current == NULL) {
      /* No big-enough blocks. Oh well, nothing we can do. */
      return NULL;
    }
  }

  void *allocated_ptr = current + 1;  // (what we'll return to the caller, hiding the header)

  if (required_size < current->size) {
    /* Now, current should be a big-enough block on the free list. But
     * it might be way too big! Time to cut it down to size and keep
     * what's left for later. */
    header *new_free_block = current + 1 + (required_size / sizeof(header));

    /* Put the new free block in the free list, in the correct (sorted) position. */
    new_free_block->size = current->size - (required_size + sizeof(header));
    new_free_block->next = current->next;
    current->size = required_size;

    if (prev == NULL) {
      free_list = new_free_block;
    } else {
      prev->next = new_free_block;
    }
  } else {
    /* We need to return the whole block, so we have to take it out of
       the free list. */
    if (prev == NULL) {
      free_list = current->next;
    } else {
      prev->next = current->next;
    }
  }
    
  return allocated_ptr;
}

/* As small chunks of memory are allocated and de-allocated,
   eventually the whole free list would consist of tiny chunks of
   memory and there wouldn't be any big chunks left over when we need
   them. To avoid that problem, we can detect when two adjacent small
   chunks are free at the same time and combine them. */
void compact_free_list() {
  header *current;
  current = free_list;
  while (current != NULL) {
    if ((current + 1 + (current->size / sizeof(header))) == current->next) {
      current->size = current->size + sizeof(header) + current->next->size;
      current->next = current->next->next;
    } else {
      current = current->next;
    }
  }
}


/* Freeing, I have arbitrarily decided, is when we will merge adjacent
   small chunks of memory together to minimize fragmentation. This may
   have undesirable performance characteristics. To make things more
   consistent, we insert blocks into the free list sorted by size, to
   avoid a potentially surprising costly sort. */
void new_free(void *ptr) {
  /* Extract the header from its hiding place just before the memory
     block ptr points to. */
  header *h = (header*)ptr - 1;

  header *prev = NULL;
  header *current = free_list;

  while(h > current && current != NULL) {
    /*    printf("%p is greater than than %p\n", h, current);
          printf("prev %p, current %p\n", prev, current);*/
    prev = current;
    current = current->next;
  }
  if(h == current) printf("Freeing already freed pointer!\n");

  /* At this point, one of three conditions holds:
     1) current is NULL (meaning h is the highest memory address in the free
     list and it just needs to be added to the end).
     2) prev is NULL, meaning h is the new first item in the list
     3) neither is NULL, in which case h needs to be inserted between them.
  */
  if (current == NULL) {
    prev->next = h;
  } else if (prev == NULL) {
    h->next = free_list;
    free_list = h;
  } else {
    h->next = current;
    prev->next = h;
  }
  compact_free_list();
}


/* Debugging helper to show what's on the free list. */
void print_free_list() {
  header *ptr = free_list;
  puts("\n*** FREE LIST ***");
  int i = 0;
  do {
    printf("Header: %p, size %d, next %p\n", ptr, ptr->size, ptr->next);
  } while ((ptr = ptr->next) != NULL && i++ < 10);
  puts("***\n");
}

```

There's a Github repo [here][https://github.com/loganmhb/malloc/blob/blog_post/new_malloc.c] with a couple of tests demonstrating how the allocator works.