---
title: Java关键字-transient
date: 2019-12-22 12:11:10
tags: 
- java
---

最近在看源码的时候看到一个关键字`transient`，之前对这个字没有印象，所以就去看了一下它的作用。

# transient的作用

首先放上来着维基百科的解释：

> Java 提供自动序列化，需要以`java.io.Serializable`接口的实例来标明对象。实现接口将类别标明为“可序列化”，然后Java在内部处理序列化。在`Serializable`接口上并没有预先定义序列化的方法，但可序列化类别可任意定义某些特定名称和签署的方法，如果这些方法有定义了，可被调用运行序列化/反序列化部分过程。该语言允许开发人员以另一个`Externalizable`接口，更彻底地实现并覆盖序列化过程，这个接口包括了保存和恢复对象状态的两种特殊方法。
>
> 在默认情况下有三个主要原因使对象无法被序列化。其一，在序列化状态下并不是所有的对象都能获取到有用的语义。例如，`Thread`对象绑定到当前Java虚拟机的状态，对`Thread`对象状态的反序列化环境来说，没有意义。其二，对象的序列化状态构成其类别兼容性缔结（compatibility contract）的某一部分。在维护可序列化类别之间的兼容性时，需要额外的精力和考量。所以，使类别可序列化需要慎重的设计决策而非默认情况。其三，序列化允许访问类别的永久私有成员，包含敏感信息（例如，密码）的类别不应该是可序列化的，也不能外部化。上述三种情形，必须实现`Serializable`接口来访问Java内部的序列化机制。标准的编码方法将字段简单转换为字节流。
>
> 原生类型以及永久和非静态的对象引用，会被编码到字节流之中。序列化对象引用的每个对象，若其中未标明为`transient`的字段，也必须被序列化；如果整个过程中，引用到的任何永久对象不能序列化，则这个过程会失败。开发人员可将对象标记为暂时的，或针对对象重新定义的序列化，来影响序列化的处理过程，以截断引用图的某些部分而不序列化。Java并不使用构造函数来序列化对象。

从上面的最后一段可以了解，如果没有添加`transient`关键字，则会被进行序列化。也就是说添加了这个关键字后就不会被序列化。

接下来我们将用一个例子来测试一下

<!--more-->

# 简单例子

首先定义一个实体类，用来被序列化。

```java
public class UserDomain implements Serializable {

	private static final long serialVersionUID = 2278149501042061657L;

	public UserDomain() {
	}

	public UserDomain(int id, String name, int age) {
		this.id = id;
		this.name = name;
		this.age = age;
	}

	private int id;

	/**
	 * 添加了 transient关键字，
	 */
	private transient String name;

	private int age;

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public int getAge() {
		return age;
	}

	public void setAge(int age) {
		this.age = age;
	}

	@Override
	public String toString() {
		return "UserDomain{" +
				"id=" + id +
				", name='" + name + '\'' +
				", age=" + age +
				'}';
	}
}
```

定义了3个字段，其中的name字段被添加上了`transient`关键字。

然后我们继续编写一个测试类

```java
public class TransientTest {
	public static void main(String[] args) {
		UserDomain user = new UserDomain(123, "姓名123", 18);
		System.out.println("序列化之前的打印");
		System.out.println(user.toString());
		//将实体对象序列化到文件中
		try (ObjectOutputStream os = new ObjectOutputStream(new FileOutputStream("user.txt"))) {
			os.writeObject(user);
			os.flush();
		} catch (Exception e) {
			e.printStackTrace();
		}
		//读取文件，将序列化后的文件读取然后重新赋值到实体对象上
		try (ObjectInputStream is = new ObjectInputStream(new FileInputStream("user.txt"))) {
			user = (UserDomain) is.readObject();
		} catch (Exception e) {
			e.printStackTrace();
		}
		System.out.println("序列化之后的打印");
		System.out.println(user.toString());
	}
}
```

我们通过构造函数创建了一个实体变量。然后将它打印出来。

接下来我们将它序列化之后写到文件中。

再将它从文件中读取出来，然后转换为实体类型。

将它再次打印出来，通过控制台打印查看区别。

```java
序列化之前的打印
UserDomain{id=123, name='姓名123', age=18}
序列化之后的打印
UserDomain{id=123, name='null', age=18}
```

可以看出，在序列化之前所有的字段都被打印出来，然后经过一次序列化后我们添加`transient`的字段就没有信息了。所以添加了这个关键字后就可以取消序列化了。

# 使用小结

1. 一旦变量被transient修饰，变量将不再是对象持久化的一部分，该变量内容在序列化后无法访问、
2. transien关键字只能修饰变量，而不能修饰方法和类。
3. **一个静态变量不管是否被transient修饰，均不能被序列化**。因为静态变量会被加载到jvm中，并且仅加载一次。所以它不管有没有`transient`关键字都不会被序列化。
4. 并不是添加了`transient`之后都不会被序列化，只是在`Serializable`接口下会这样，如果实现的是`Externalizable`它还是会被序列化。

# 参考

- [https://zh.wikipedia.org/wiki/%E5%BA%8F%E5%88%97%E5%8C%96#Java](https://zh.wikipedia.org/wiki/序列化#Java)
- https://www.cnblogs.com/lanxuezaipiao/p/3369962.html