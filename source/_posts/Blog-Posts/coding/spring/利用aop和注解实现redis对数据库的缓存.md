---
title: 利用aop和注解实现redis对数据库的缓存
date: 2019-07-24
categories:
  - notes
tags:
  - Spring
  - AOP
  - Redis
---

**利用[AOP](https://www.liunaijie.top/2019/09/04/spring/Spring笔记/#AOP)和注解的方式实现redis的数据缓存**

[代码链接](https://github.com/liunaijie/learn-demo/tree/master/learn-spring-boot-demo/learn-springboot-redis-demo)

之前一直没有用到redis，最近想学习一下redis，那么首先想到的就是将数据库的结果添加到缓存中，那么下次访问的时候如果命中缓存了就可以不用访问数据库，节省了时间。  

我在网上搜索了几篇文章，发现他们都是在每个业务逻辑里面添加缓存判断，伪代码如下：

```java
public Object method1(Object param1){
	//如果param1的结果在缓存中存在，直接返回
	if(redis has cache){
		return redis result;
	}
	Object dbResult = dao.select();
	redis.add(dbResult);
	return dbResult
}
```

如果这样写，那么在每个需要缓存的地方都需要添加与本身业务无关的代码，对代码的侵入比较大。所以我利用aop和注解实现了一个方法，在需要缓存的地方添加该注解就可以实现缓存，不会对代码有侵入。最终实现调用的结果如下：

```java
@Override
@EnableRedisCache(Key = "user", Time = 100000)
public ResultBean getUserById(Long id) {
	return ResultUtil.success(userDao.selectById(id));
}

/**
* 同上面的方法一样，这个没有添加 EnableRedisCache，所以每次都会走数据库，
* 上面的方法添加了注解会先走缓存，如果没有再走数据库
*
* @param id
* @return
*/
@Override
public ResultBean getUserNoCache(Long id) {
	return ResultUtil.success(userDao.selectById(id));
}
```


该实现主要是利用了aop原理，通过对`EnableRedisCache`注解进行拦截，如果有该注解就进入到拦截方法中。

使用`@interface`即可声明一个注解，`@Target({ElementType.METHOD})`表示要用在方法上。

```java
@Target({ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
public @interface EnableRedisCache {

	/**
	 * redis存储的key值
	 * 自定义redis存储的前缀，后面在redis存储的key值为：访问的类名+方法名+key值+参数名称+参数值
	 * @return
	 */
	String Key() default "";

	/**
	 * 设置一个默认的缓存时间
	 *
	 * @return
	 */
	long Time() default 1000L;

	/**
	 * 缓存的时间单位
	 */
	TimeUnit TIME_UNIT() default TimeUnit.MILLISECONDS;

}
```

然后实现对该注解的拦截：  

由于我之前没有调用过redis的api，所以闹出了一个问题，我想设置在redis中存储的时间时调用了`operations.set(key,val,time)`这个方法，我进入这个方法看了一眼也没有仔细看，以为这个就是调用了默认的时间单位设置过期时间。结果这样调用后不行了，进入redis查看数据也不对。就很奇妙。经朋友提现调用的方法不对，需要调用的是`operations.set(key,val,time,time_unit)`这样的方法。

```java
@Aspect
@Component
public class RedisAspect {

	@Autowired
	private RedisTemplate redisTemplate;
	
    // 对有EnableRedisCache注解的方法进行拦截
	@Around("@annotation(enableRedisCache)")
	public Object around(ProceedingJoinPoint proceedingJoinPoint, EnableRedisCache enableRedisCache) {
		// 将类名，方法名，注解中的key值，参数名称与参数值 作为redis存储的键
		MethodSignature signature = (MethodSignature) proceedingJoinPoint.getSignature();
		Method method = signature.getMethod();
		String className = proceedingJoinPoint.getTarget().getClass().getName();
		String methodName = signature.getName();
		LocalVariableTableParameterNameDiscoverer u = new LocalVariableTableParameterNameDiscoverer();
		String[] paramNames = u.getParameterNames(method);
		Object[] args = proceedingJoinPoint.getArgs();
		String key = enableRedisCache.Key();
		String redisKey = className + methodName + key;
		if (args != null && paramNames != null) {
			for (int i = 0; i < args.length; i++) {
				redisKey += paramNames[i] + ":" + args[i];
			}
		}
		long cacheTime = enableRedisCache.Time();
		TimeUnit timeUnit = enableRedisCache.TIME_UNIT();
		Object result = getCacheByRedisKey(proceedingJoinPoint, redisKey, cacheTime, timeUnit);
		return result;
	}

	private Object getCacheByRedisKey(ProceedingJoinPoint proceedingJoinPoint, String redisKey, long cacheTime, TimeUnit timeUnit) {
        // 从redis里面读取key为rediskey的值，如果不存在那么就走数据库，如果存在就将缓存中内容返回
		ValueOperations<String, Object> operations = redisTemplate.opsForValue();
		try {
			if (redisTemplate.hasKey(redisKey)) {
				ResultBean cacheResult = (ResultBean) operations.get(redisKey);
				if (cacheResult == null) {
					return null;
				}
				System.out.println("通过缓存获取数据");
				return cacheResult;
			} else {
				//如果缓存中没有数据，则执行方法，查询数据库，dbResult是请求方法返回的信息
				// 我将注解放在service层上，并且service统一了返回信息格式
				ResultBean dbResult = (ResultBean) proceedingJoinPoint.proceed();
				System.out.println("通过数据库获取数据");
				// 要将返回信息和实体类都实现序列化的接口
				operations.set(redisKey, dbResult, cacheTime, timeUnit);
				return dbResult;
			}
		} catch (Exception e) {
			e.printStackTrace();
		} catch (Throwable throwable) {
			throwable.printStackTrace();
		}
		return null;
	}

}

```

这里只有查询的方法，后面添加更新和删除方法时需要将存储到redis中的key（这里用了类名、方法名等拼接）进行修改，不然执行更新和删除时不方便找的key。