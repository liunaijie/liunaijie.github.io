---
title: MongoDB初接触
date: 2019-11-15 16:23:37
toc: true
categories: "NoSQL"
tags: 
	- NoSQL
	- mongodb
thumbnail: https://raw.githubusercontent.com/liunaijie/images/master/silhouette-of-man-facing-the-ocean-2962224.jpg
---

一直想了解一下非关系型数据库，今天用`MongoDB`写了一个小 demo。对MongoDB 算是有了一个小认识。

# 启动 MongoDB

我用的 docker 创建的 MongoDB 实例。

```shell
docker pull mongo
docker run -itd --name noAuthMongo -p 27017:27017 mongo #无密码启动
```

# 代码

项目是用的 springboot 框架。

1. 添加依赖

    ```maven
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-mongodb</artifactId>
    </dependency>
    ```

    

2. 设置 MongoDB 连接属性

    ````yaml
    # 有设置账户密码的方式
    spring.data.mongodb.uri: mongodb://user:pwd@localhost:27017/database
    # 无账户密码的方式
    spring.data.mongodb.uri: mongodb://localhost:27017/database
    # 集群连接方式
    spring.data.mongodb.uri: mongodb://user:pwd@ip1:port1,ip2:port2/database
    ````

    <!--more-->

3. 建立 bean 对象

    ```java
    @Data
    public class Order {
    
    	private int id;
    
    	private String name;
    
    	private String address;
    
    }
    ```

    一个实体对象，有 id，name，address 三个属性。

4. 创建 dao 接口

    ```java
    public interface OrderDao {
    
    	/**
    	 * 新增订单
    	 *
    	 * @param order
    	 */
    	void insertOrder(Order order);
    
    	/**
    	 * 更新订单
    	 *
    	 * @param order
    	 */
    	void updateOrder(Order order);
    
    	/**
    	 * 删除订单
    	 *
    	 * @param id
    	 */
    	void deleteOrder(int id);
    
    	/**
    	 * 根据 id 查询一个
    	 *
    	 * @param id
    	 * @return
    	 */
    	Order finOne(int id);
    
    	/**
    	 * 查询全部
    	 *
    	 * @return
    	 */
    	List<Order> findAll();
    
    	/**
    	 * 根据名称查询
    	 * @param name
    	 * @return
    	 */
    	List<Order> find(String name);
    
    }
    ```

    

5. 具体实现

    ```java
    @Repository
    public class OrderDaoImpl implements OrderDao {
    
    	@Autowired
    	private MongoTemplate mongoTemplate;
    
    	@Override
    	public void insertOrder(Order order) {
    		mongoTemplate.save(order);
    	}
    
    	@Override
    	public void updateOrder(Order order) {
    		Query query = new Query(Criteria.where("id").is(order.getId()));
    		Update update = new Update().set("address", order.getAddress()).set("name", order.getName());
    		//更新一条
    		mongoTemplate.updateFirst(query, update, Order.class);
    		//更新多条
    		//mongoTemplate.updateMulti(query, update, Order.class);
    	}
    
    	@Override
    	public void deleteOrder(int id) {
    		Query query = new Query(Criteria.where("id").is(id));
    		mongoTemplate.remove(query, Order.class);
    	}
    
    	@Override
    	public Order finOne(int id) {
    		Query query = new Query(Criteria.where("id").is(id));
    		return mongoTemplate.findOne(query, Order.class);
    	}
    
    	@Override
    	public List<Order> findAll() {
    		return mongoTemplate.findAll(Order.class);
    	}
    
    	@Override
    	public List<Order> find(String name) {
    		Query query = new Query(Criteria.where("name").is(name));
    //		return mongoTemplate.find(query, Order.class, "name");
    		return mongoTemplate.find(query, Order.class);
    	}
    
    
    }
    ```

6. 编写测试类

    ```java
    @RunWith(SpringRunner.class)
    @SpringBootTest
    class OrderDaoTest {
    
    
    	@Autowired
    	private OrderDao orderDao;
    
    
    	@Test
    	public void insert() {
    		Order order = new Order();
    		order.setId(9);
    		order.setName("999");
    		order.setAddress("99999");
    		orderDao.insertOrder(order);
    	}
    
    	@Test
    	public void update() {
    		Order order = new Order();
    		order.setId(9);
    		order.setName("999");
    		order.setAddress("99999update");
    		orderDao.updateOrder(order);
    	}
    
    	@Test
    	public void find() {
    		Order order = new Order();
    		order.setId(9);
    		order.setName("999");
    		order.setAddress("99999update");
    		Assert.assertEquals(order, orderDao.finOne(9));
    	}
    
    	@Test
    	public void findAll() {
    		List<Order> lists = orderDao.findAll();
    	}
    
    	@Test
    	public void findName() {
    		//先创建多个 name 为 222的记录
    		List<Order> lists = orderDao.find("222");
    	}
    
    }
    ```

7. 数据库可视化软件查看

    我之前一直使用`navicat`，发现它也能连接 MongoDB 的数据库。所以就直接使用它来进行查看。

