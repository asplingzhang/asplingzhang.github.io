---
layout: default
title:  "WeakPtr(Weak pointers) in WebRTC"
date:   2024-01-05 15:31:33 +0800
categories: [webrtc]
---

# Weak pointers in WebRTC

**1. Purpose of Weak Pointers:**

- **Non-owning pointers:** They don't affect the lifetime of the object they point to.
- **Can be invalidated:** The pointer can be reset to nullptr, typically when the object is about to be deleted.
- **Use cases:**
    - Accessing objects owned by others, without influencing their lifetime.
    - Breaking circular references to prevent memory leaks.
    - Handling objects that might be deleted asynchronously.

**2. Key Classes:**

- `WeakPtr`: Represents a weak pointer to an object. It can be checked for validity before using it to access the object.
- `WeakPtrFactory`: Manages the creation of weak pointers. It provides a way to get weak references to the managed object and to invalidate all weak pointers created by it.
- `WeakReference`: An intermediate object that holds a reference to a `Flag`.
- `WeakReference::Flag`: An object that tracks the validity of the weak pointer. When the object to which the weak pointer is pointing is destroyed, the flag is set to invalid.
- `WeakReferenceOwner`: Owns a `Flag` and provides a way to get a `WeakReference` to the flag. It ensures that when it is destroyed, it invalidates the flag, thus invalidating all `WeakPtr` instances that reference it.


```
+-----------------------------------+ 1   +---------------------------------+
| <<class>>                         +<----+ <<class>>                       |
| WeakReference::Flag               |     | WeakReferenceOwner              |
+-----------------------------------+     +---------------------------------+
| + Invalidate() : void             |     | + GetRef() : WeakReference      |
| + IsValid() const : bool          |     | + Invalidate() : void           |
| - is_valid_ : bool                |     | + HasRefs() const : bool        |
|                                    |     | - flag_ : scoped_refptr<Flag>   |
+---^-------------------------------+     +---^-----------------------------+
    |                                       |
    | 1                                     | 1
    |                                       |
+---+-----------------------------------+   |   +-------------------------------+
| <<class>>                             |<--+   | <<class>>                     |
| WeakReference                         |       | WeakPtrBase                   |
+---------------------------------------+       +-------------------------------+
| + is_valid() const : bool             |       | + ref_ : WeakReference        |
| - flag_ : scoped_refptr<const Flag>   |       +-------------------------------+
+---------------------------------------+
           ^ 1
           |
           | 1               0..1
           | +-----------------+-------------------------------------------+
           |                   |                                           |
          +|-------------------|-------------------------------------------|--------+
           |                   |                                           |        |
+----------|-------------------|-----------------+    +--------------------|--------|------------------+
| <<class>>|                   |                 |    | <<class>>          |        |                  |
| WeakPtr  |                   |                 |    | WeakPtrFactory     |        |                  |
+----------|-------------------|-----------------+    +--------------------|--------|------------------+
|          |                   |                 |    | + GetWeakPtr()     |        | : WeakPtr        |
|          |                   |                 |    | + InvalidateWeakPtrs() : void                  |
|          |                   |                 |    | + HasWeakPtrs() const : bool                   |
|          |                   |                 |    | - ptr_ : T*                                     |
|          |                   |                 |    +------------------------------------------------+
|          |                   |                 |
|          |                   |                 |
+----------|-------------------|-----------------+
| + get() const : T*            |                 |
| + operator*() const : T&      |                 |
| + operator->() const : T*     |                 |
| + reset() : void              |                 |
| + operator bool() const       |                 |
| - ptr_ : T*                   |                 |
+-------------------------------+                 |
                                                  |
                                                  |
+-------------------+          +------------------|--------+      +-----------------------+
| <<typeparam>>     |          | <<typeparam>>    |        |      | <<typeparam>>         |
| T                 |<>--------+ U                 |<-------+      | U                     |
+-------------------+                             +---------------+
```


**3. How They Work:**

- **`WeakPtrFactory<T>`:**
    - Stores a raw pointer to the target object.
    - Provides a `GetWeakPtr()` method to create `WeakPtr<T>` instances.
    - Can invalidate all existing `WeakPtr<T>` instances using `InvalidateWeakPtrs()`.
- **`WeakPtr<T>`:**
    - Stores a WeakReference, which indirectly points to the target object.
    - Can be checked for validity using `get()` or boolean conversion.
    - Can be dereferenced using `*` or `->` only if valid.

**4. Thread Safety:**

- Weak pointers themselves are safe to **pass between threads**. They are just small objects containing information about the target object and its reference count.
- However, **dereferencing** a weak pointer (using `*` or `->`) actually accesses the target object. This access needs to be synchronized to avoid race conditions, which can occur when multiple threads try to access the same object concurrently.
- By requiring dereferencing to happen on the original thread, we ensure that only one thread is accessing the object at a time, leading to predictable and safe behavior.

**5. Example Scenario:**

- A Controller class creates a WeakPtrFactory for itself.
- It can then pass WeakPtr<Controller> instances to Workers.
- Workers can safely use the WeakPtr to call methods on the Controller if it still exists.
- If the Controller is deleted, the WeakPtrs automatically become invalid, preventing crashes.

```C++
// EXAMPLE:
//
//  class Controller {
//   public:
//    Controller() : weak_factory_(this) {}
//    void SpawnWorker() { Worker::StartNew(weak_factory_.GetWeakPtr()); }
//    void WorkComplete(const Result& result) { ... }
//   private:
//    // Member variables should appear before the WeakPtrFactory, to ensure
//    // that any WeakPtrs to Controller are invalidated before its members
//    // variable's destructors are executed, rendering them invalid.
//    WeakPtrFactory<Controller> weak_factory_;
//  };
//
//  class Worker {
//   public:
//    static void StartNew(const WeakPtr<Controller>& controller) {
//      Worker* worker = new Worker(controller);
//      // Kick off asynchronous processing...
//    }
//   private:
//    Worker(const WeakPtr<Controller>& controller)
//        : controller_(controller) {}
//    void DidCompleteAsynchronousProcessing(const Result& result) {
//      if (controller_)
//        controller_->WorkComplete(result);
//    }
//    WeakPtr<Controller> controller_;
//  };
```

**6. Additional Notes:**

- The implementation is borrowed from Chromium, with minor modifications.
- Thread-safety is crucial for correct usage.
- Weak pointers can be useful for breaking circular references and managing object lifetimes in complex scenarios.

# Weak pointers must be dereferenced and invalidated on the same thread or TaskQueue where they were created for thread-safety reasons.

Weak pointers must be dereferenced and invalidated on the same thread or `TaskQueue` where they were created for thread-safety reasons. Here's why this is important:

1. **Race Conditions**: If weak pointers could be dereferenced or invalidated on any thread, there would be a risk of race conditions. For example, one thread could be checking the validity of a weak pointer while another thread invalidates it. This could lead to accessing a dangling pointer, which could result in undefined behavior and hard-to-debug crashes.

2. **Atomicity**: The operations on the internal state of a weak pointer (like checking validity or invalidation) are typically not atomic. This means they are not guaranteed to be performed as a single, uninterruptible operation. Thus, performing these operations from multiple threads without synchronization could lead to inconsistent states.

3. **Design Assumptions**: The design of many weak pointer implementations, including the one in the WebRTC project, assumes single-threaded access to certain operations. The sequence checker used within the weak pointer implementation (`webrtc::SequenceChecker`) ensures that the expected single-threaded usage pattern is adhered to by asserting that certain operations are only called from the thread they are bound to.

4. **Simplicity and Performance**: Enforcing single-thread access for certain operations allows for a simpler and more performant implementation. Without the need for locking or atomic operations to secure thread-safety across all operations, the code can be faster and easier to reason about.

5. **Lifecycle Guarantees**: By binding to a particular thread or `TaskQueue`, the lifecycle of the object to which the weak pointer refers can be managed more predictably. The object's owner can ensure that objects are not unexpectedly accessed or modified from other threads, which could complicate the object's destruction process.

In the particular implementation provided, weak pointers issued by a `WeakPtrFactory` can be passed safely between threads because simply holding a weak pointer does not require thread-safe access. However, when you actually dereference a weak pointer (i.e., use it to access the object it points to) or invalidate it (mark all weak pointers from a factory as null because the object is about to be destroyed), it must be done in the context of the thread or `TaskQueue` it is bound to.

This design choice helps prevent common concurrency issues and aligns with best practices for managing object lifetimes in a multithreaded environment.

