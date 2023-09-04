---
title: SpringBoot使用@ControllerAdvice处理异常
date: 2019-11-24 16:39:13
categories:
- [coding, spring]
tags: 
- spring
---

# 背景

我们知道，当前端请求的后端程序抛出异常时，此时的 http 状态码变成了 500，并有一大串错误信息。今天要做的是整合后台返回信息，不管后台程序有异常，都能返回一个统一格式的信息，前端根据里面的信息来判断是否请求失败。

定义一下正常返回的信息如下：

```json
{
    code:1,
    msg:"请求成功", //或其他自定义信息
    data:{
        //这里存储这个接口的返回信息
    }
}
```

错误的信息如下：

```json
{
    code:-1, //可以根据不同的情况返回不同的状态码
    msg:"请求失败", //或其他自定义信息
    data:{}
}
```

<!--more-->

# 实现

在 spring 框架下，这个要求我们可以利用 aop 去实现它，比如对我们所有的接口进行一个横切，对返回信息遇到异常后进行处理。

在 springboot 框架下，已经有现成的东西让我们可以直接去使用了。那就直接上代码了。

定义返回信息实体类：

```java
@Data
public class ResultBean<T> {

	private String code;
	private String msg;
	private T data;

}
```

然后定义一个自定义异常，必须继承自`RuntimeException`。如果直接继承`Exception`则事务不一定回滚

```java
@Data
public class AppException extends RuntimeException {
	/**
	 * 异常状态码
	 */
	private String code;

	/**
	 * 异常提示信息
	 */
	private String msg;

	public AppException(ResultEnums resultEnums) {
		super(resultEnums.getMsg());
		this.code = resultEnums.getCode();
		this.msg = resultEnums.getMsg();
	}

	public AppException(String msg) {
		super(msg);
		this.code = "-1";
		this.msg = msg;
	}

}
```

由于异常信息较多，为了便于管理，我们定义一个枚举

```java
public enum ResultEnums {
    
	SUCCESS("1", "成功！"),
    FAIL("-1", "失败！");
    
    private String code;

	private String msg;

	ResultEnums(String code, String msg) {
		this.code = code;
		this.msg = msg;
	}

	public String getCode() {
		return code;
	}

	public String getMsg() {
		return msg;
	}
}
```

为了不再每一个返回信息和处理异常都使用 new 一个返回信息类，定义一个工具类来进行处理

```java
public class ResultUtil {

	/**
	 * 固定成功提示，不返回信息
	 *
	 * @return resultBean
	 */
	public static ResultBean success() {
		return success(null);
	}

	/**
	 * 固定成功提示，返回信息
	 *
	 * @param object 具体信息
	 * @return resultBean
	 */
	public static ResultBean success(Object object) {
		ResultBean result = new ResultBean();
		result.setCode(ResultEnums.SUCCESS.getCode());
		result.setMsg(ResultEnums.SUCCESS.getMsg());
		result.setData(object);
		return result;
	}

	/**
	 * 自定义成功提示，返回信息
	 *
	 * @param resultEnums
	 * @param object
	 * @return
	 */
	public static ResultBean success(ResultEnums resultEnums, Object object) {
		ResultBean result = new ResultBean();
		result.setCode(resultEnums.getCode());
		result.setMsg(resultEnums.getMsg());
		result.setData(object);
		return result;
	}

	/**
	 * 失败
	 *
	 * @param code    错误码
	 * @param message 错误信息
	 * @return resultBean
	 */
	public static ResultBean fail(String code, String message) {
		ResultBean result = new ResultBean();
		result.setCode(code);
		result.setMsg(message);
		result.setData(null);
		return result;
	}

	public static ResultBean fail(ResultEnums resultEnums) {
		ResultBean result = new ResultBean();
		result.setCode(resultEnums.getCode());
		result.setMsg(resultEnums.getMsg());
		result.setData(null);
		return result;
	}

}
```

然后是最关键的一步：

```java
@ControllerAdvice
public class ExceptionHandle {

	/**
	 * 捕获异常 针对不同异常返回不同内容的固定格式信息
	 * 拦截所有的异常，并且返回 json 格式的信息
	 * @param e 异常
	 * @return resultBean
	 */
	@ExceptionHandler(value = Exception.class)
	@ResponseBody
	public ResultBean handle(Exception e) {
		if (e instanceof AppException) {
            //如果是我们自定义的异常，就直接返回我们异常里面设置的信息
			AppException appException = (AppException) e;
			return ResultUtil.fail(appException.getCode(), appException.getMessage());
		} else if (e instanceof HttpRequestMethodNotSupportedException) {
            //对其他的异常进行处理，如果是请求方法错误，我们设置 code 和 msg 进行返回。
			return ResultUtil.fail(ResultEnums.REQUEST_PARAMETER_MISSING.getCode(), ResultEnums.REQUEST_PARAMETER_MISSING.getMsg());
		} else {
			return ResultUtil.fail(ResultEnums.UN_KNOW_ERROR.getCode(), ResultEnums.UN_KNOW_ERROR.getMsg());
		}
	}

}
```

# 测试代码

我们新建一个接口：

```java
@RestController
public class Test {

	@GetMapping(value = "/noError")
	public Object noError() {
		String data = "ok,you are right";
		return ResultUtil.success(data);
	}

	@GetMapping(value = "/hasError")
	public Object hasError() {
		//对于业务异常我们可以抛出自定义异常
//		throw new AppException(ResultEnums.FAIL);
		int a = 1 / 0;
		//由于 0 不能做除数，所以会抛出异常
		return ResultUtil.success(a);
	}

}
```

然后我们访问对于的地址，可以看到正常时的信息和遇到异常时的信息在外部格式是一致的，不会因为服务器出现错误就出现 500 的错误了。

# @ControllerAdvice 下其他注解

处理@ExceptionHandler 外还有两个注解

- ### @InitBinder

    主要作用是绑定一些自定义的参数

- ### @ModelAttribute

    除了处理用于接口参数可以用于转换对象类型的属性之外，还可以用来进行方法的声明。

这两个注解在此篇文章中不再记录。