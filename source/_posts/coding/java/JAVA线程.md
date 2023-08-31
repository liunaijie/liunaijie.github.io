---
title: JAVA线程
date: 2019-09-22 20:33:39
tags: 
- java/thread
---

# 基础概念

线程的所有状态：

这些状态都在 `Thread`中的`State`枚举中定义：

```java
public enum State {
    //表示刚刚创建的线程，这种线程还没开始执行
    NEW,
 	//在 start() 方法调用后，线程开始执行，此时状态处于 RUNABLE
    RUNNABLE,
	//如果线程在执行过程中遇到 synchronized 同步块，就会进入 BLOCKED 阻塞状态，直到获取请求的锁
    BLOCKED,
	//等待状态，WAITING 会无时间限制的等待，TIMED_WAITING 会有时间限制
    WAITING,
    TIMED_WAITING,
	//线程执行完毕，表示结束
    TERMINATED;
}
```

## 初始线程

1. `Thread`类

2. `Runable`接口

    `Thread`类中调用`start()`方法之后会让线程执行`run()`方法，而`run()`方法中又是对`Runable`实例的调用

    ```java
     /* What will be run. */
    private Runnable target;
    
    @Override
    public void run() {
        if (target != null) {
            target.run();
        }
    }
    ```

<!--more-->

## 中断线程

```java
//中断线程
public void Thread.interrupt();
//判断线程是否被中断
public boolean Thread.isInterrupted();
//判断线程是否被中断，并清除当前的中断状态
public static boolean Thread.interrupted();
```

线程中断并不会让线程立即退出，而是给线程发送一个通知，告诉目标线程，有人希望你退出，至于具体要不要退出还是由目标线程自己决定。我们来看一个例子。

```java
public static void main(String[] args) throws InterruptedException {
    Thread t1 = new Thread() {
        @Override
        public void run() {
            while (true) {
                if (Thread.currentThread().isInterrupted()) {
                    System.out.println("interrupted");
                    break;
                }
                System.out.println("i am running...");
            }
        }
    };
    t1.start();
    Thread.sleep(2000);
    t1.interrupt();
}
```

在第 16 行对线程进行中断，如果没有第 6 行的判断，线程得到中断信号后不会停止还是会继续运行。这里添加了一个判断，如果被中断则退出。

## 等待(wait)和通知(notify)

首先要明确，这两个方法并不是输入`Thread`类中的，而是输入`Object`类，这就意味着任何对象都可以调用这两个方法。

使用`wait()`方法时，它必须包含在`synchronzied`语句块中，这也很好理解，对当前对象进行等待，那么首先要获取当前对象。多个线程同时访问一个对象，如果要获取这个对象就要加锁才能获取这个对象。

当使用`wait()`方法后，线程进入了`WAITING`状态，然后锁定对象的其他线程使用`notify()`方法对其进行唤醒，如果同时有多个线程处于等待状态，`notify`唤醒的线程是随机的，也可使用`notifyAll()`方法唤醒所有的线程。使用`wait()`方法后，会释放当前占用的锁。

使用了`notify()`方法后并不会释放锁，也就是被唤醒的线程虽然被唤醒了但是还是无法运行，因为它要获取锁才能进行，而这把锁还是刚才对其进行`notify()`方法的线程上。

## 等待线程结束(join)和谦让(yield)

1. join()

有时候一个线程的输入是依赖于另一个线程的输入的。此时，就需要等待依赖线程执行完毕，才能继续执行，可以使用`join()`方法来实现这个功能

```java
// 无限等待，会一直阻塞当前线程
public final void join() throws InterruptedException;
// 给定最大等待时间，如果超出时间目标线程仍在执行，不会再继续等待
public final synchronized void join(long millis) throws InterruptedException;
```

下面给出一个例子：

```java
// 定义一个共享变量
volatile static int i = 0;

public static class AddThread extends Thread {
    @Override
    public void run() {
        // 对变量 i 进行循环加
        for (; i < 1000; i++) {
        }
    }
}

public static void main(String[] args) {
    AddThread addThread = new AddThread();
    addThread.start();
    //打印 i 的值
    System.out.println(i);
}
```

这时打印出来的值并不确定，他可能是 0~1000 里面的任意一个值。

```java
// 定义一个共享变量
volatile static int i = 0;

public static class AddThread extends Thread {
    @Override
    public void run() {
        // 对变量 i 进行循环加
        for (; i < 1000; i++) {
        }
    }
}

public static void main(String[] args) {
    AddThread addThread = new AddThread();
    addThread.start();
    try {
        addThread.join();
    } catch (InterruptedException e) {
        e.printStackTrace();
    }
    //打印 i 的值
    System.out.println(i);
}
```

这时在第 17 行添加了对目标线程的等待，所以打印会在目标线程完成后执行所以最终结果为 1000。

```java
volatile static int i = 0;

public static class AddThread extends Thread {
    @Override
    public void run() {
        try {
            Thread.sleep(2000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        for (; i < 1000; i++) {
        }
    }
}

public static void main(String[] args) {
    AddThread addThread = new AddThread();
    addThread.start();
    try {
        addThread.join(1000);
    } catch (InterruptedException e) {
        e.printStackTrace();
    }
    System.out.println(i);
}
```

而这一段，我在目标线程中先执行 2 秒的睡眠，然后再对变量加，设置最大等待时长为 1 秒，所以最终打印的结果为 0。

2. yield()

```java
public static native void yield();
```

当使用该方法后，当前线程会让出**CPU**。

程序最终在计算机上是一条指令，我们当前线程正在执行一条指令，最终这条执行是由硬件也就是 CPU 来执行的，如果这个执行执行的时间过长，其他指令也就需要等待（假设只有一个 CPU），使用这个方法后可以让出 CPU 来，让其他指令先执行。当前指令的状态被改变，然后 CPU 选择一个指令来执行，这时有可能会选到刚刚释放 CPU 也就是执行`yield()`方法的线程。

## 线程组

```java
ThreadGroup threadGroup = new ThreadGroup("GroupName");
Thread t1 = new Thread(threadGroup,new ThreadGroupName(),"t1");
Thread t2 = new Thread(threadGroup,new ThreadGroupName(),"t2");
t1.start();
t2.start();
System.out.println(threadGroup.activeCount());
threadGroup.list();
```

线程组主要有两个方法：`activeCount()`返回活动线程的总数，但由于线程是动态的，所以这个值只是一个估计值。`list()`方法打印这个线程组中所有线程的线程信息。

## 守护线程（后台线程）

```java
Thread t1 = new Thread();
t1.setDaemon(true);
t1.start();
```

通过`setDaemon()`方法可以设置线程是否为守护线程，要注意的是这个方法必须在`start()`方法前设置，不然线程已经启动起来就无法改变他的状态了。会得到一个异常，但是这时程序依然可以正常运行：

```java
Exception in thread "main" java.lang.IllegalThreadStateException
at java.lang.Thread.setDaemon(Thread.java:1359)
    ...
```

当一个 Java 应用中，只有守护线程时，Java 虚拟机会自然退出。

## 线程优先级

对于不同的线程，他对应的业务级别可能会不一样，所以需要对其设置不同的线程优先级。

在 Java 中，使用 1 到 10 表示线程优先级。一般可以使用内置的三个静态标量表示：

```JAVA
public final static int MIN_PRIORITY = 1;  // 最低的等级
public final static int NORM_PRIORITY = 5; // 平常的等级
public final static int MAX_PRIORITY = 10; // 最高的等级
```

通过`setPriority()`方法设置线程的优先级。

## JAVA内存模型（JMM）

主要围绕多线程的原子性、可见性、有序性

原子性：是指一个操作是不可中断的。即使在多个线程一起执行的时候，一个操作一旦开始，就不会被其他线程干扰。

可见性：是指当一个线程修改了某一个共享变量的值，其他线程是否能够立即知道这个修改。

有序性：当我们在代码中顺序的写下 a,b,c 三条语句时，按照理想顺序他是按照 a,b,c 这个顺序执行的。但是如果出现指令重排的情况下，它的顺序就可能会发生改变。

# volatile

`volatile`关键字：修饰一个变量，当多个线程都使用这个变量时，当有一个线程对变量进行了修改，其他线程中的值也会发生改变。

```java
//定义一个变量
volatile static boolean flag = true;

public static void main(String[] args) {
    //启动一个线程，当变量为 true 时会一直运行
    Thread t1 = new Thread(()->{
        while (flag){
            System.out.println("t1 running");
        }
        System.out.println("t1 end");
    });
	// 启动一个线程，将变量修改为 false
    Thread t2 = new Thread(()->{
        flag = false;
    });
    t1.start();
    t2.start();
}
```

通过打印结果可以看出 t2 线程对变量的修改也影响了 t1 线程的运行，这就是可见性。

但`volatile`并不能代替锁！它也无法保证一些复合操作的原子性。

# synchronized

synchronized 的作用是实现线程间的同步，它的工作是对同步的代码加锁。使得每一次，只能有一个线程进入同步块，从而保证线程间的安全性。

关键字`synchronized`可以有多种用法：

- 指定加锁对象：对给定对象加锁，进入同步代码前要获取给定对象的锁

    ```java
    public class SynchronizedTest {
    	// 指定加锁对象
    	Object o = new Object();
    
    	public void m(){
    		synchronized (o){
    			System.out.println("i am running");
    			try {
    				Thread.sleep(2000);
    			} catch (InterruptedException e) {
    				e.printStackTrace();
    			}
    		}
    	}
    
    	public static void main(String[] args) {
    		SynchronizedTest s1 = new SynchronizedTest();
    		SynchronizedTest s2 = new SynchronizedTest();
    		s1.m();
    		s2.m();
    	}
    
    }
    /*
    指定了加锁的对象为新建的 object 对象
    打印出结果后会睡两秒钟后再进行打印，说明同一时间只有一个线程访问了 m() 方法
    */
    ```

- 直接作用于实例方法：相当于对当前实例加锁，进入同步代码前要获取当前实例的锁

    ```java
    public class SynchronizedTest implements Runnable {
    
    	static int i = 0;
    
    	public synchronized void increase() {
    		i++;
    	}
    
    	@Override
    	public void run() {
    		for (int j = 0; j <10000 ; j++) {
    			increase();
    		}
    	}
    
    	public static void main(String[] args) throws InterruptedException {
    		//新建一个实例
            SynchronizedTest test = new SynchronizedTest();
    		// 两个线程启动的是同一个实例
            Thread t1 = new Thread(test);
    		Thread t2 = new Thread(test);
    		t1.start();
    		t2.start();
    		t1.join();
    		t2.join();
    		System.out.println(i);
    	}
    
    }
    ```

    如果将上面代码中的第 20，21 行换成下面的两句则会出现不同的结果

    ```java
    Thread t1 = new Thread(new SynchronizedTest());
    Thread t2 = new Thread(new SynchronizedTest());
    ```

    由于线程启动的是不同的实例，所以最终的输出结果会不正确。

- 直接作用于静态方法：相当于对当前类加锁，进入同步代码前要获取当前类的锁

    ```java
    public class SynchronizedTest {
    	//作用于静态方法
    	public synchronized static void m(){
    		System.out.println("i am running");
    		try {
    			Thread.sleep(2000);
    		} catch (InterruptedException e) {
    			e.printStackTrace();
    		}
    	}
    
    	public static void main(String[] args) {
    		SynchronizedTest.m();
    		SynchronizedTest.m();
    	}
    
    }
    ```

    除了用于线程同步、确保线程安全外，synchronized 还可以保持线程间的可见性和有序性。从可见性的角度而言，synchronized 完全可以替代 volatile 的功能，只是使用不够方便，没有 volatile 轻量。从有序性上，被 synchronized 限制的代码块每次执行都要获取锁，从而保证了有序性。换句话说，被 synchronized 限制的多线程其实的串行执行的。

# Lock

## 重入锁ReentrantLock

### 加锁

重入锁可以完全替代 synchronized 关键字，在 jdk1.5之前的版本中，重入锁的性能远远好于 synchronized，但从 jdk1.6 开始，jdk 在 synchronized 上做了大量的优化，使得两者的差距并不大。

```java
public class ReenterLock implements Runnable {
	// 初始化ReentrantLock锁
	public static ReentrantLock lock = new ReentrantLock();

	public static int i=0;

	@Override
	public void run() {
		for (int j = 0; j <10000 ; j++) {
			//加锁
            lock.lock();
			i++;
            //释放锁
			lock.unlock();
		}
	}

	public static void main(String[] args) throws InterruptedException {
		ReenterLock reenterLock = new ReenterLock();
		Thread t1 = new Thread(reenterLock);
		Thread t2 = new Thread(reenterLock);
		t1.start();
		t2.start();
		t1.join();
		t2.join();
		System.out.println(i);
	}

}
```

可以看出来，使用ReentrantLock时需要显式的加锁与释放锁，所以一定要记得释放锁，不然其他线程就没法访问。

并且可以多次执行加锁的操作：

```java
lock.lock();
lock.lock();
i++:
lock.unlock();
lock.unlock();
```

但是要记住，上了几次锁，就要释放几次锁，不然其他线程无法访问。如果释放锁的次数多于加锁的次数，则会得到一个`java.lang.IllegalMonitorStateException`异常。

### 中断响应

当启动线程后，可能因为某些原因需要关闭（中断）它，这时就需要线程有响应关闭（中断）的能力。使用`lockInterruptibly()`方法就可以对中断进行响应，在等待锁的过程中，可以响应中断。

### 尝试获取锁

`tryLock()`：如果锁未被其他线程占用，则直接获取锁。如果锁被其他线程占用，则不会进行等待，立即返回 false 

`tryLock(long timeout, TimeUnit unit)`：第一个参数表示等待时长，第二个参数表示计时单位。表示最多会等待参数的时间，到时间后如果还未申请到锁，则会返回 false 

### 公平锁

之前的情况，锁的申请都是不公平的，也就是当锁被释放后，谁获取到锁是不一定的。重入锁运行我们创建一个公平锁：当参数为 true 时，表示锁的公平的。

```java
public ReentrantLock(boolean fair)
```

想一下，要实现公平锁，那就是谁先来谁获取这把锁，先到先得的意思。那么我们就要维护一个队列来保存这个顺序。所以公平锁的实现成本比较高，性能相对也较低。

ReentrantLock 主要由几个重要的方法

1. lock()：获取锁，如果锁已经被占用，则等待。
2. lockInterruptibly()：获得锁，但优先响应中断
3. tryLock()：尝试获取锁，如果成功，则获取到锁，并返回 false，如果失败则立即返回 false
4. tryLock(long time,TimeUnit unit)：在给定时间内尝试获取锁
5. unlock()：释放锁

## Condition

Condition 是与重入锁相关联的，正如`wait()`和`notify()`与`synchronized`合作使用一样。

`Condition`接口主要提供的方法如下：

```java
//使当前线程等待，同时释放锁。当线程被中断时，也能跳出等待。
void await();
//与 await 相同，但是不会响应中断
void awaitUninterruptibly();
//进行一定时间的等待
boolean await(long time,TimeUnit unit);
//最多等待到设定的时间
boolean awaitUntil(Date deadline);
//通知。当等待线程接收到通知后，会继续进行
void signal();
//通知全部
void signalAll();
```

通过Lock 接口的`newCondition()`方法生成一个与当前重入锁绑定的 Condition 实例。利用 Condition 对象，我们可以让线程在合适的时间等待，或者在某一个特定的时刻得到通知，继续执行。比如`ArrayBlockinQueue`就使用了重入锁和 Condition 对象。

```java
// 定义一个重入锁
final ReentrantLock lock;
// 定义条件
private final Condition notEmpty;

private final Condition notFull;

public ArrayBlockingQueue(int capacity, boolean fair) {
    if (capacity <= 0)
        throw new IllegalArgumentException();
    this.items = new Object[capacity];
    //构造函数将变量初始化
    lock = new ReentrantLock(fair);
    notEmpty = lock.newCondition();
    notFull =  lock.newCondition();
}

public void put(E e) throws InterruptedException {
    checkNotNull(e);
    final ReentrantLock lock = this.lock;
    // 先加锁
    lock.lockInterruptibly();
    try {
        while (count == items.length)
            // 如果数量等于长度，则表示满了，则写线程进行等待
            notFull.await();
       //当没满的情况或被通知后进行添加
        enqueue(e);
    } finally {
        //最后将锁释放
        lock.unlock();
    }
}

private void enqueue(E x) {
    // assert lock.getHoldCount() == 1;
    // assert items[putIndex] == null;
    final Object[] items = this.items;
    items[putIndex] = x;
    if (++putIndex == items.length)
        putIndex = 0;
    count++;
    //添加完成后，通知读的线程，有数据可以读了
    notEmpty.signal();
}

public E take() throws InterruptedException {
    final ReentrantLock lock = this.lock;
    lock.lockInterruptibly();
    try {
        while (count == 0)
            //如果数量为 0 则表示空，则等待放入，读线程进行等待
            notEmpty.await();
        //不为 0 或者被通知后，进行读取数据
        return dequeue();
    } finally {
        //最后释放锁
        lock.unlock();
    }
}

private E dequeue() {
    // assert lock.getHoldCount() == 1;
    // assert items[takeIndex] != null;
    final Object[] items = this.items;
    @SuppressWarnings("unchecked")
    E x = (E) items[takeIndex];
    items[takeIndex] = null;
    if (++takeIndex == items.length)
        takeIndex = 0;
    count--;
    if (itrs != null)
        itrs.elementDequeued();
    //读取完成后，通知写线程，可以写了。
    notFull.signal();
    return x;
}
```

# 信号量（Semaphore）

之前的`synchronized`、`ReentrantLock`一次都只允许一个线程访问一个资源，而信号量可以指定多个线程，同时访问一个资源，主要的构造函数如下：

```java
//指定信号量的准入数，最多能有多少个线程同时进入
public Semaphore(int permits);
//第二个线程可以指定是否公平
public Semaphore(int permits, boolean fair);
```

它里面主要的方法有：

```java
//获取锁并响应中断
public void acquire();
//获取锁但不响应中断
public void acquireUninterruptibly();
//尝试获取锁
public boolean tryAcquire();
//在一定时间内尝试获取锁，若超时仍未获取锁则取消等待
public boolean tryAcquire(long timeout,TimeUnit unit);
//释放锁
public void release();
```

看一下用信号量编写的简单例子：

```java
public class SemapDemo implements Runnable {
	//定义一个信号量，指定最多 5 个同时访问
	Semaphore semaphore = new Semaphore(5);

	@Override
	public void run() {
		try {
            //获取锁
			semaphore.acquire();
			Thread.sleep(2000);
			System.out.println(Thread.currentThread().getName()+"----"+System.currentTimeMillis());
		} catch (InterruptedException e) {
			e.printStackTrace();
		}finally {
			//释放锁
            semaphore.release();
		}
	}

	public static void main(String[] args) {
		//新建一个线程，用 20 个线程执行上面的任务
        ExecutorService service = Executors.newFixedThreadPool(20);
		SemapDemo semapDemo = new SemapDemo();
		for (int i = 0; i <20 ; i++) {
			service.submit(semapDemo);
		}
	}

}
/*
从打印结果可以看出，打印是 5 个线程同时执行的
*/
```

# 读写锁 ReadWriteLock

之前的`synchronized`和`ReentrantLock`等都会进行加锁，然而有些对数据不会有改变的情况它也会对其加锁，也就导致了速度慢。如果一个系统中，读的次数（对数据不改变的情况）多于写的次数（对数据有改变的情况）。其实可以对写进行加锁，而对读则没必要加锁。

- 读-读：无锁
- 读-写：加锁
- 写-写：加锁

来看一下例子：

```java
public class ReadWriteLockDemo {

	private static ReentrantReadWriteLock readWriteLock = new ReentrantReadWriteLock();
	//定义读锁
	private static Lock readLock = readWriteLock.readLock();
	//定义写锁
	private static Lock writeLock = readWriteLock.writeLock();

	private int value;

	public int handleRead(Lock lock) throws InterruptedException {
		try {
			lock.lock();
			//睡眠 1 秒钟
            TimeUnit.SECONDS.sleep(1);
			return value;
		} finally {
			lock.unlock();
		}
	}

	public void handleWrite(Lock lock, int index) throws InterruptedException {
		try {
			lock.lock();
            //睡眠 1 秒钟
			TimeUnit.SECONDS.sleep(1);
			value = index;
		} finally {
			lock.unlock();
		}
	}

	public static void main(String[] args) {
		ReadWriteLockDemo demo = new ReadWriteLockDemo();

		Runnable read = new Runnable() {
			@Override
			public void run() {
				try {
					demo.handleRead(readLock);
				} catch (InterruptedException e) {
					e.printStackTrace();
				}
			}
		};

		Runnable write = new Runnable() {
			@Override
			public void run() {
				try {
					demo.handleWrite(writeLock, new Random().nextInt());
				} catch (InterruptedException e) {
					e.printStackTrace();
				}
			}
		};
		for (int i = 0; i < 18; i++) {
			new Thread(read).start();
		}

		for (int i = 0; i < 2; i++) {
			new Thread(write).start();
		}
	}

}
```

启动 18 个读线程，2个写线程。每个线程中都要一个 1 秒的睡眠。如果都是串行执行的，则需要 20+ 秒的时间。从执行结果看出，执行时间只是 2+秒。所以可以看出，写线程是串行的，读线程是并行执行的。

这两个方法都接受的是 Lock 对象，如果我们不是传入读写锁，而是传入一个`ReentrantLock`对象实例。则会执行 20+秒。

# CountDownLatch

门闩，或者倒计时器，初始化时指定一个值，当这个值变成 0 时才会等待完成，继续执行。

```java
public CountDownLatch(int count); //计数个数
```

来看一个具体的例子，

```java
public class CountDownLatchDemo implements Runnable {
	// 初始化条件为 10，当变成 0 后才会继续执行
	public static final CountDownLatch countDownLatch = new CountDownLatch(10);

	@Override
	public void run() {
		try {
            //随机睡眠，模拟不同条件的线程
			TimeUnit.SECONDS.sleep(new Random().nextInt(10));
			System.out.println(" conditional completion~ ~ ~ ~");
		} catch (InterruptedException e) {
			e.printStackTrace();
		} finally {
            //执行完毕后，执行 倒计时减一
			countDownLatch.countDown();
		}
	}

	public static void main(String[] args) {
		ExecutorService service = Executors.newFixedThreadPool(10);
		CountDownLatchDemo demo = new CountDownLatchDemo();
		for (int i = 0; i < 10; i++) {
			//10 个线程执行任务
            service.submit(demo);
		}
		try {
            //等待计数器完成
			countDownLatch.await();
			System.out.println(" all finish ");
		} catch (InterruptedException e) {
			e.printStackTrace();
		}finally {
			service.shutdown();
		}
	}

}
```

# CyclicBarrier

它与 CountDownLatch 非常类似，它也可以实现线程间的计数等待，但它的功能更加复杂。看一下它的构造函数

```java
public CyclicBarrier(int parties,Runnable barrierAction);
```

它多了一个`Runnable`参数，也就是说他可以在一次计数完成后再执行一次计数然后执行`barrierAction`。

```java
public class CyclicBarrierDemo {

	public static class First implements Runnable {

		private CyclicBarrier cyclicBarrier;

		public First(CyclicBarrier cyclicBarrier) {
			this.cyclicBarrier = cyclicBarrier;
		}

		@Override
		public void run() {
			try {
				//进行第一次等待，等待满足 10 个线程才会继续执行，不够则继续等待
				System.out.println(Thread.currentThread().getName() + " on wait...");
				cyclicBarrier.await();
				// 睡眠模拟每个线程的任务
				TimeUnit.SECONDS.sleep(new Random().nextInt(10));
				System.out.println(Thread.currentThread().getName() + " finish work...");
			} catch (InterruptedException e) {
				e.printStackTrace();
			} catch (BrokenBarrierException e) {
				e.printStackTrace();
			}
		}
	}

	public static class Second implements Runnable {

		@Override
		public void run() {
			System.out.println("second task is running ");
		}
	}

	public static void main(String[] args) {
		CyclicBarrier cyclicBarrier = new CyclicBarrier(10, new Second());
		ExecutorService service = Executors.newFixedThreadPool(10);
		for (int i = 0; i < 10; i++) {
			service.submit(new First(cyclicBarrier));
		}
		service.shutdown();
	}

}

/*
打印结果
pool-1-thread-1 on wait...
省略其他线程打印
pool-1-thread-10 on wait...
second task is running 
pool-1-thread-3 finish work
省略其他线程打印
pool-1-thread-4 finish work
*/
```

我们可以看出，由于设置了`await()`方法，所以线程会先进行等待，满足条件（10 个线程）后会先执行了`barrierAction`的任务，然后再继续执行下面的代码。

**CountDownLatch 与 CyclieBarrier 两者区别**

CountDownLatch：一个任务需要其他几个条件的完成才能继续执行

CyclieBarrier：满足条件后需要先执行一个其他的任务后再执行下面的代码块。

# 线程池

线程的创建和销毁，以及线程上下文的切换都比较花费资源，有时候在业务逻辑上花费的时间可能还不如创建销毁和切换花费的时间，这时候就需要线程池。

为了避免系统频繁的创建和销毁线程，我们可以让创建的线程进行复用。当需要使用线程时，先从线程池中拿一个空闲线程，当工作完成后，不去关闭线程，而是把线程还给线程池，方便下次调用。

在 jdk 中提供了一些线程池方法，在`Executors`类中。

```java
public static ExecutorService newFixedThreadPool(int nThreads) {
    return new ThreadPoolExecutor(nThreads, nThreads,
                                  0L, TimeUnit.MILLISECONDS,
                                  new LinkedBlockingQueue<Runnable>());
}

public static ExecutorService newSingleThreadExecutor() {
    return new FinalizableDelegatedExecutorService
        (new ThreadPoolExecutor(1, 1,
                                0L, TimeUnit.MILLISECONDS,
                                new LinkedBlockingQueue<Runnable>()));
}

public static ExecutorService newCachedThreadPool() {
    return new ThreadPoolExecutor(0, Integer.MAX_VALUE,
                                  60L, TimeUnit.SECONDS,
                                  new SynchronousQueue<Runnable>());
}

public static ScheduledExecutorService newSingleThreadScheduledExecutor() {
    return new DelegatedScheduledExecutorService
        (new ScheduledThreadPoolExecutor(1));
}

public static ScheduledExecutorService newScheduledThreadPool(int corePoolSize) {
    return new ScheduledThreadPoolExecutor(corePoolSize);
}


public static ExecutorService newWorkStealingPool() {
    return new ForkJoinPool
        (Runtime.getRuntime().availableProcessors(),
         ForkJoinPool.defaultForkJoinWorkerThreadFactory,
         null, true);
}
```

- newFixedThreadPool()：返回一个固定线程数量的线程池。线程池中的线程数量始终不变。当有新任务提交到线程池中，如果线程池中有空闲的线程，则会交给空闲线程去立即执行。如果没有，则新任务会被暂存到一个任务队列中，待有线程空闲时，便处理任务队列中的任务，并且会先执行等待时间最久的任务（由于LinkedBlockingQueue，后面细讲）。

- newSingleThreadExecutor()：返回只有一个线程的线程池。若有任务提交，当这个线程空闲则会执行。否则，会将这个任务保存在一个任务队列中，线程空闲后，按先入先出的顺序执行队列任务。

- newCachedThreadPool()：这个线程池的数量不固定，当有新任务提交时，如果没有空闲的线程则会新启动一个线程执行该任务，任务执行完毕后暂时不会关闭线程，而是等待 60 秒后关闭（在参数中设置）。如果在这 60 秒内有新任务提交，则会使用该线程去执行新任务，如果没有则到时间自动关闭。

- newSingleThreadScheduledExecutor()：返回一个`ScheduledExecutorService`对象，线程池大小为 1。可以在给定时间执行某任务：可以在某个固定的延时之后执行，也可以周期性的执行。

- newScheduledThreadPool()：与`newSingleThreadScheduledExecutor()`相同，不过可以指定线程池中的线程数量。

- newWorkStealingPool()：精灵线程。它在执行完自己线程的任务后会自动去任务队列拿取线程进行执行。现在有 3 个线程，每个线程都维护自己的任务队列，第一个任务队列里面有 5 个任务，第二个有 1 个，第三个有 4 个。那么在第二个执行完成后会向第一个里面队尾拿取一个任务进行执行。

    



# 参考

1. <<实战 Java 高并发程序设计>> -葛一鸣，郭超，电子工业出版社