---
title: Iceberg
date: 2023-11-23
categories:
  - notes
tags:
  - Iceberg
---
# 前言
本文将记录一下iceberg表的文件存储结构, 数据写入流程, 查询流程的等. 基于Spark引擎.
<!-- more -->
# 准备工作
1. java8
2. spark binary
3. iceberg jar, 并放到spark binary的`jars`文件夹下
由于在Spark 3.3之后才支持Time Travel功能，所以我们使用Spark 3.5并下载相应的`iceberg-spark-runtime-3.5_2.12-1.4.2` jar包，放入到spark的jars文件夹下.
iceberg的meta信息使用avro格式存储，我们可以使用这个命令来查看文件内容`java -jar avro-tools-1.11.1.jar tojson xxx.avro`

# 正式测试
## 创建Catalog
这里使用`type=hadoop`创建一个名为`local`的Catalog，文件存储位置为当前路径下的`warehouse`目录
```
./bin/spark-sql \
--conf spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions \
    --conf spark.sql.catalog.spark_catalog=org.apache.iceberg.spark.SparkSessionCatalog \
    --conf spark.sql.catalog.spark_catalog.type=hive \
    --conf spark.sql.catalog.local=org.apache.iceberg.spark.SparkCatalog \
    --conf spark.sql.catalog.local.type=hadoop \
    --conf spark.sql.catalog.local.warehouse=$PWD/warehouse
```

```sql
CREATE TABLE local.db.tb01 (id bigint not null, name string, ts timestamp not null) USING iceberg PARTITIONED BY (year(ts))
```
这张表中包含三个字段，设置了两个不能为空，并且分区字段通过`ts`这个字段计算而来。
下面插入一些数据
```sql
insert into local.db.tb01 values 
( 1, 'name1', to_timestamp('2023-12-31 00:12:00')), 
...,
( 50, 'name50', to_timestamp('2023-12-31 00:12:00')),
( 51, 'name51', to_timestamp('2022-12-31 00:12:00')), 
...,
( 100, 'name100', to_timestamp('2022-12-31 00:12:00'))
;
```
## 插入数据
插入了100条数据，时间分别为50条23年，50条22年。
接下来我们看一下这时的文件存储结构：
![Pasted image 20231211140927.png](https://raw.githubusercontent.com/liunaijie/images/master/202312112145937.png)

iceberg表的文件存储结构如官网上的图所示。我们根据这张图以及我们生成的文件内容来具体分析一下。
![Pasted image 20231211111111.png](https://raw.githubusercontent.com/liunaijie/images/master/202312112147123.png)
- data
存储数据的文件夹，里面的文件存储格式与Hive存储没什么区别。唯一区别在分区文件夹的命名上，iceberg这里的命名由于我们使用了转化函数，多了`_year`的后缀。
- metadata/version-hint.text
这个文件记录了当前使用的metadata文件版本
- metadata/v[version].metadata.json
```json
{
    "format-version": 2,
    "table-uuid": "6109e725-f2be-4dd1-bb39-f990c2b38727",
    "location": "/Desktop/iceberg/spark-3.5.0-bin-hadoop3/warehouse/db/tb01",
    "last-sequence-number": 1,
    "last-updated-ms": 1702262809304,
    "last-column-id": 3,
    "current-schema-id": 0,
    "schemas": [
        {
            "type": "struct",
            "schema-id": 0,
            "fields": [
                {
                    "id": 1,
                    "name": "id",
                    "required": true,
                    "type": "long"
                },
                {
                    "id": 2,
                    "name": "name",
                    "required": false,
                    "type": "string"
                },
                {
                    "id": 3,
                    "name": "ts",
                    "required": true,
                    "type": "timestamptz"
                }
            ]
        }
    ],
    "default-spec-id": 0,
    "partition-specs": [
        {
            "spec-id": 0,
            "fields": [
                {
                    "name": "ts_year",
                    "transform": "year",
                    "source-id": 3,
                    "field-id": 1000
                }
            ]
        }
    ],
    "last-partition-id": 1000,
    "default-sort-order-id": 0,
    "sort-orders": [
        {
            "order-id": 0,
            "fields": []
        }
    ],
    "properties": {
        "owner": "",
        "write.parquet.compression-codec": "zstd"
    },
    "current-snapshot-id": 1284014949645635555,
    "refs": {
        "main": {
            "snapshot-id": 1284014949645635555,
            "type": "branch"
        }
    },
    "snapshots": [
        {
            "sequence-number": 1,
            "snapshot-id": 1284014949645635555,
            "timestamp-ms": 1702262809304,
            "summary": {
                "operation": "append",
                "spark.app.id": "local-1702262387758",
                "added-data-files": "2",
                "added-records": "100",
                "added-files-size": "2261",
                "changed-partition-count": "2",
                "total-records": "100",
                "total-files-size": "2261",
                "total-data-files": "2",
                "total-delete-files": "0",
                "total-position-deletes": "0",
                "total-equality-deletes": "0"
            },
            "manifest-list": "/Desktop/iceberg/spark-3.5.0-bin-hadoop3/warehouse/db/tb01/metadata/snap-1284014949645635555-1-cb1e6fc2-203d-4ca6-96ac-2bb13d0b4502.avro",
            "schema-id": 0
        }
    ],
    "statistics": [],
    "snapshot-log": [
        {
            "timestamp-ms": 1702262809304,
            "snapshot-id": 1284014949645635555
        }
    ],
    "metadata-log": [
        {
            "timestamp-ms": 1702262797607,
            "metadata-file": "/Desktop/iceberg/spark-3.5.0-bin-hadoop3/warehouse/db/tb01/metadata/v1.metadata.json"
        }
    ]
}
```
从里面的内容我们可以看出，这个文件存储了如下信息：
1. 文件存储位置 `location`
2. 当前以及历史表结构信息 `current-schema-id`, `schemas`
每个版本记录了包含的字段名称，类型以及是否不能为空。
3. 分区信息 `partition-specs`
分区使用到的字段，以及如何转化的函数
4. 当前版本以及历史版本信息 `current-snapshot-id`, `snapshots`
在snapshot结构中，记录了snapshot文件的位置，表结构信息，文件变更的一些统计信息（例如增加文件的数量，增加的记录条数，总记录条数，文件大小等等）

- metadata/snap-[snapshotId]-[attemptId]-[commitUUID].avro
我们使用如下命令来查看avro的内容：
```shell
java -jar avro-tools-1.11.1.jar tojson metadata/snap-1284014949645635555-1-cb1e6fc2-203d-4ca6-96ac-2bb13d0b4502.avro
```
文件内容如下
```json
{
    "manifest_path": "/Desktop/iceberg/spark-3.5.0-bin-hadoop3/warehouse/db/tb01/metadata/cb1e6fc2-203d-4ca6-96ac-2bb13d0b4502-m0.avro",
    "manifest_length": 7056,
    "partition_spec_id": 0,
    "content": 0,
    "sequence_number": 1,
    "min_sequence_number": 1,
    "added_snapshot_id": 1284014949645635555,
    "added_data_files_count": 2,
    "existing_data_files_count": 0,
    "deleted_data_files_count": 0,
    "added_rows_count": 100,
    "existing_rows_count": 0,
    "deleted_rows_count": 0,
    "partitions": {
        "array": [
            {
                "contains_null": false,
                "contains_nan": {
                    "boolean": false
                },
                "lower_bound": {
                    "bytes": "4\u0000\u0000\u0000"
                },
                "upper_bound": {
                    "bytes": "5\u0000\u0000\u0000"
                }
            }
        ]
    }
}
```
这个文件记录了manifest的文件记录，以及一些统计信息

- metadata/[commitUUID]-m[manifestCount].avro
```json
{
	"status": 1,
	"snapshot_id": {
		"long": 1284014949645635555
	},
	"sequence_number": null,
	"file_sequence_number": null,
	"data_file": {
		"content": 0,
		"file_path": "/Desktop/iceberg/spark-3.5.0-bin-hadoop3/warehouse/db/tb01/data/ts_year=2022/00000-39-ed797eca-366a-46f0-9e07-e2c1cd94da03-00002.parquet",
		"file_format": "PARQUET",
		"partition": {
			"ts_year": {
				"int": 52
			}
		},
		"record_count": 50,
		"file_size_in_bytes": 1140,
		"column_sizes": {
			"array": [
				{
					"key": 1,
					"value": 118
				},
				{
					"key": 2,
					"value": 150
				},
				{
					"key": 3,
					"value": 70
				}
			]
		},
		"value_counts": {
			"array": [
				{
					"key": 1,
					"value": 50
				},
				{
					"key": 2,
					"value": 50
				},
				{
					"key": 3,
					"value": 50
				}
			]
		},
		"null_value_counts": {
			"array": [
				{
					"key": 1,
					"value": 0
				},
				{
					"key": 2,
					"value": 0
				},
				{
					"key": 3,
					"value": 0
				}
			]
		},
		"nan_value_counts": {
			"array": []
		},
		"lower_bounds": {
			"array": [
				{
					"key": 1,
					"value": "3\u0000\u0000\u0000\u0000\u0000\u0000\u0000"
				},
				{
					"key": 2,
					"value": "name100"
				},
				{
					"key": 3,
					"value": "\u0000\u0014\u0083Ü\rñ\u0005\u0000"
				}
			]
		},
		"upper_bounds": {
			"array": [
				{
					"key": 1,
					"value": "d\u0000\u0000\u0000\u0000\u0000\u0000\u0000"
				},
				{
					"key": 2,
					"value": "name99"
				},
				{
					"key": 3,
					"value": "\u0000\u0014\u0083Ü\rñ\u0005\u0000"
				}
			]
		},
		"key_metadata": null,
		"split_offsets": {
			"array": [
				4
			]
		},
		"equality_ids": null,
		"sort_order_id": {
			"int": 0
		}
	}
}
{
	"status": 1,
	"snapshot_id": {
		"long": 1284014949645635555
	},
	"sequence_number": null,
	"file_sequence_number": null,
	"data_file": {
		"content": 0,
		"file_path": "/Desktop/iceberg/spark-3.5.0-bin-hadoop3/warehouse/db/tb01/data/ts_year=2023/00000-39-ed797eca-366a-46f0-9e07-e2c1cd94da03-00001.parquet",
		"file_format": "PARQUET",
		"partition": {
			"ts_year": {
				"int": 53
			}
		},
		"record_count": 50,
		"file_size_in_bytes": 1121,
		"column_sizes": {
			"array": [
				{
					"key": 1,
					"value": 106
				},
				{
					"key": 2,
					"value": 150
				},
				{
					"key": 3,
					"value": 69
				}
			]
		},
		"value_counts": {
			"array": [
				{
					"key": 1,
					"value": 50
				},
				{
					"key": 2,
					"value": 50
				},
				{
					"key": 3,
					"value": 50
				}
			]
		},
		"null_value_counts": {
			"array": [
				{
					"key": 1,
					"value": 0
				},
				{
					"key": 2,
					"value": 0
				},
				{
					"key": 3,
					"value": 0
				}
			]
		},
		"nan_value_counts": {
			"array": []
		},
		"lower_bounds": {
			"array": [
				{
					"key": 1,
					"value": "\u0001\u0000\u0000\u0000\u0000\u0000\u0000\u0000"
				},
				{
					"key": 2,
					"value": "name1"
				},
				{
					"key": 3,
					"value": "\u0000ô\u0096h¼\r\u0006\u0000"
				}
			]
		},
		"upper_bounds": {
			"array": [
				{
					"key": 1,
					"value": "2\u0000\u0000\u0000\u0000\u0000\u0000\u0000"
				},
				{
					"key": 2,
					"value": "name9"
				},
				{
					"key": 3,
					"value": "\u0000ô\u0096h¼\r\u0006\u0000"
				}
			]
		},
		"key_metadata": null,
		"split_offsets": {
			"array": [
				4
			]
		},
		"equality_ids": null,
		"sort_order_id": {
			"int": 0
		}
	}
}
```
该文件记录了存储文件的位置，以及每个文件的统计信息，例如最大最小值，每个为空/不为空的数量等。在某些查询条件下，这样可以加快查询时的过滤速度，因为不再需要读取存储文件。
从这里可以看出iceberg的数据文件管理时文件级别的，分区管理，字段统计也是到文件级别，与Hive的目录级别不同。

在iceberg官网上，列举了几个重要的功能：
- Schema evolution
- Hidden partitioning
- Partition layout evolution
- Time travel

## 更新字段
我们下面通过几个变更来看一下这几个功能，例如更改表结构，更改分区字段
首先我们做一次行级别的字段更新操作：
```sql
MERGE INTO local.db.tb01 t USING (select id, name from values (1, 'update_name1'), (50,'update_name50') TAB (id, name)) u on t.id = u.id WHEN MATCHED THEN UPDATE SET t.name = u.name;
```
![Pasted image 20231211145801.png](https://raw.githubusercontent.com/liunaijie/images/master/202312112148009.png)

这时我们看一下新的`v3.metadata.json`文件，我这里只贴出来有关键更改的部份
```json
"current-snapshot-id": 7996194920797103527,
"snapshots": [
	{
		"sequence-number": 1,
		"snapshot-id": 1284014949645635555,
		"timestamp-ms": 1702262809304,
		"summary": {
			"operation": "append",
			"spark.app.id": "local-1702262387758",
			"added-data-files": "2",
			"added-records": "100",
			"added-files-size": "2261",
			"changed-partition-count": "2",
			"total-records": "100",
			"total-files-size": "2261",
			"total-data-files": "2",
			"total-delete-files": "0",
			"total-position-deletes": "0",
			"total-equality-deletes": "0"
		},
		"manifest-list": "/Desktop/iceberg/spark-3.5.0-bin-hadoop3/warehouse/db/tb01/metadata/snap-1284014949645635555-1-cb1e6fc2-203d-4ca6-96ac-2bb13d0b4502.avro",
		"schema-id": 0
	},
	{
		"sequence-number": 2,
		"snapshot-id": 7996194920797103527,
		"parent-snapshot-id": 1284014949645635555,
		"timestamp-ms": 1702277078925,
		"summary": {
			"operation": "overwrite",
			"spark.app.id": "local-1702262387758",
			"added-data-files": "1",
			"deleted-data-files": "1",
			"added-records": "50",
			"deleted-records": "50",
			"added-files-size": "1164",
			"removed-files-size": "1121",
			"changed-partition-count": "1",
			"total-records": "100",
			"total-files-size": "2304",
			"total-data-files": "2",
			"total-delete-files": "0",
			"total-position-deletes": "0",
			"total-equality-deletes": "0"
		},
		"manifest-list": "/Desktop/iceberg/spark-3.5.0-bin-hadoop3/warehouse/db/tb01/metadata/snap-7996194920797103527-1-4bf081db-c14d-4cbc-9689-b6770adca787.avro",
		"schema-id": 0
	}
],
"snapshot-log": [
	{
		"timestamp-ms": 1702262809304,
		"snapshot-id": 1284014949645635555
	},
	{
		"timestamp-ms": 1702277078925,
		"snapshot-id": 7996194920797103527
	}
],
"metadata-log": [
	{
		"timestamp-ms": 1702262797607,
		"metadata-file": "/Desktop/iceberg/spark-3.5.0-bin-hadoop3/warehouse/db/tb01/metadata/v1.metadata.json"
	},
	{
		"timestamp-ms": 1702262809304,
		"metadata-file": "/Desktop/iceberg/spark-3.5.0-bin-hadoop3/warehouse/db/tb01/metadata/v2.metadata.json"
	}
]
```
首先`current-snapshot-id`更改为最新的版本，其次`snapshots`中多了这次更新的操作

接下来再看下snapshot文件, snapshot文件中包含了两行，
```json
{
	"manifest_path": "/Desktop/iceberg/spark-3.5.0-bin-hadoop3/warehouse/db/tb01/metadata/4bf081db-c14d-4cbc-9689-b6770adca787-m1.avro",
	"manifest_length": 7008,
	"partition_spec_id": 0,
	"content": 0,
	"sequence_number": 2,
	"min_sequence_number": 2,
	"added_snapshot_id": 7996194920797103527,
	"added_data_files_count": 1,
	"existing_data_files_count": 0,
	"deleted_data_files_count": 0,
	"added_rows_count": 50,
	"existing_rows_count": 0,
	"deleted_rows_count": 0,
	"partitions": {
		"array": [
			{
				"contains_null": false,
				"contains_nan": {
					"boolean": false
				},
				"lower_bound": {
					"bytes": "5\u0000\u0000\u0000"
				},
				"upper_bound": {
					"bytes": "5\u0000\u0000\u0000"
				}
			}
		]
	}
}
{
	"manifest_path": "/Desktop/iceberg/spark-3.5.0-bin-hadoop3/warehouse/db/tb01/metadata/4bf081db-c14d-4cbc-9689-b6770adca787-m0.avro",
	"manifest_length": 7071,
	"partition_spec_id": 0,
	"content": 0,
	"sequence_number": 2,
	"min_sequence_number": 1,
	"added_snapshot_id": 7996194920797103527,
	"added_data_files_count": 0,
	"existing_data_files_count": 1,
	"deleted_data_files_count": 1,
	"added_rows_count": 0,
	"existing_rows_count": 50,
	"deleted_rows_count": 50,
	"partitions": {
		"array": [
			{
				"contains_null": false,
				"contains_nan": {
					"boolean": false
				},
				"lower_bound": {
					"bytes": "4\u0000\u0000\u0000"
				},
				"upper_bound": {
					"bytes": "5\u0000\u0000\u0000"
				}
			}
		]
	}
}
```

我们分别看一下这两个manifest文件
```json
-- m0.avro
{
	"status": 0,
	"snapshot_id": {
		"long": 1284014949645635555
	},
	"sequence_number": {
		"long": 1
	},
	"file_sequence_number": {
		"long": 1
	},
	"data_file": {
		"content": 0,
		"file_path": "/Desktop/iceberg/spark-3.5.0-bin-hadoop3/warehouse/db/tb01/data/ts_year=2022/00000-39-ed797eca-366a-46f0-9e07-e2c1cd94da03-00002.parquet",
		...
	}
}
{
	"status": 2,
	"snapshot_id": {
		"long": 7996194920797103527
	},
	"sequence_number": {
		"long": 1
	},
	"file_sequence_number": {
		"long": 1
	},
	"data_file": {
		"content": 0,
		"file_path": "/Desktop/iceberg/spark-3.5.0-bin-hadoop3/warehouse/db/tb01/data/ts_year=2023/00000-39-ed797eca-366a-46f0-9e07-e2c1cd94da03-00001.parquet",
		...
	}
}

---- m1.avro
{
	"status": 1,
	"snapshot_id": {
		"long": 7996194920797103527
	},
	"sequence_number": null,
	"file_sequence_number": null,
	"data_file": {
		"content": 0,
		"file_path": "/Desktop/iceberg/spark-3.5.0-bin-hadoop3/warehouse/db/tb01/data/ts_year=2023/00000-47-8b27a8c6-3477-4aa3-aba8-72cb57d77a5a-00001.parquet",
		...
	}
}

```
这里有个关键字段`status`，它的值有三个: 0 , 1, 2. 分别表示EXISTING, ADDED, DELETED. (`ManifestEntry`类中的枚举值)
通过这个值我们再来看这两个文件中的三个JSON结构
- status: 0 , file_path = xxx
- status: 2 , file_path = xxx
- status: 1 , file_path = xxx
根据枚举值的定义我们可以知道，三个文件中，我们有一个需要保留，一个需要删除，并且有一个新增文件。
我们再来看文件以及我们想一下我们这次的变动：对一个分区下的两条记录做了字段更新。从文件变动我们可以知道，这次的变动新生成了一个文件，那么原来的文件就需要标记为删除。而没有修改过的分区文件应该保留。

## Time Travel
我们上面对表进行过一次更改，我们现在如果直接查询得到的结果是更改之后的记录，现在我们想查询更改之前的记录。
```sql
select * from local.db.tb01.snapshots
```
首先我们可以根据这个SQL查询出现存的所有snapshot版本， 然后我们可以使用这个SQL来查询指定版本的数据，我们还可以根据时间，tag来查询，具体语法参考[这里](https://iceberg.apache.org/docs/latest/spark-queries/#time-travel)
```sql
select * from local.db.tb01.snapshots VERSION AS OF <SNAPSHOT_ID>;
```

## Schema evolution
我们对表结构进行一下[更改](https://iceberg.apache.org/docs/latest/spark-ddl/#alter-table--add-column)
```sql
ALTER TABLE local.db.tb01
ADD COLUMNS (
	new_col string comment 'new added col for test'
);
```
这时有新增了一个v4.metadata.json文件，文件的变更为`schemas`部分的变更。将当前snapshot的schema版本标记为最新的schema.
我们再进行一下记录的更新
```sql
MERGE INTO local.db.tb01 t USING (select id, name, ew_col from values (2, 'schema_update2', 'new added'), (99,'update_name50', 'new added') TAB (id, name, ew_col)) u on t.id = u.id WHEN MATCHED THEN UPDATE SET t.name = u.name , t.ew_col = u.ew_col
;
```
更新完的文件结构如下：
![Pasted image 20231211155153.png](https://raw.githubusercontent.com/liunaijie/images/master/202312112148124.png)
这次让我们猜测一下manifest中的变动, 这次我们更新了两个分区内的文件，之前的文件都需要被标记为删除，新产生的两个文件都应该被标记为新增。
让我们直接看一下`82b5d4d8-8e28-4e01-ae54-45106e8af0b8`这三个manifest文件
首先是m0
```json
{
    "status": 2,
    "data_file": {
        "content": 0,
        "file_path": "/Desktop/iceberg/spark-3.5.0-bin-hadoop3/warehouse/db/tb01/data/ts_year=2023/00000-47-8b27a8c6-3477-4aa3-aba8-72cb57d77a5a-00001.parquet",
        ...
    }
}
```
其次是m1
```json
{
    "status": 2,
    "data_file": {
        "content": 0,
        "file_path": "/Desktop/iceberg/spark-3.5.0-bin-hadoop3/warehouse/db/tb01/data/ts_year=2022/00000-39-ed797eca-366a-46f0-9e07-e2c1cd94da03-00002.parquet",
        ...
    }
}
```
最后是m2
```json
{
	"status": 1,
	"data_file": {
		"content": 0,
		"file_path": "/Desktop/iceberg/spark-3.5.0-bin-hadoop3/warehouse/db/tb01/data/ts_year=2022/00000-7-0f9c9bf6-db10-47d7-9e69-ba2b9f90bb85-00002.parquet",
		...
	}
}
{
	"status": 1,
	"data_file": {
		"content": 0,
		"file_path": "/Desktop/iceberg/spark-3.5.0-bin-hadoop3/warehouse/db/tb01/data/ts_year=2023/00000-7-0f9c9bf6-db10-47d7-9e69-ba2b9f90bb85-00001.parquet",
		...
}
```
结果与我们预期的相符：两个分区内分别新增了一个文件，而上一次更新的两个文件被标记为删除。

**注意：这里只记录增量的更改，也就是记录了从上一次的变动到这一次变动之间的更改**

通过某个snapshot文件，我们可以得知这个版本的数据使用的表结构是什么，最终使用到的数据文件有哪些，通过这些我们可以得到这个时刻的完整数据。并且可以通过manifest中的统计信息帮助在某些情况下的加速查询。
# Reference
- [# Iceberg Table Spec [](https://iceberg.apache.org/spec/#iceberg-table-spec)](https://iceberg.apache.org/spec/)
- [# Iceberg 原理分析](https://zhuanlan.zhihu.com/p/488467438)