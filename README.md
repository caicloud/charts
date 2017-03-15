# Chart 模版配置规范定义

规范主要用于定义 Chart 配置文件 values.yaml 的逻辑结构和类型。  

### 基础结构描述
配置文件使用 yaml 格式，并且在实际使用中转换为 json 格式。  
标准 配置文件结构如下：
```yaml
# 顶级配置 key ，固定为 _config
_config: 
  # 元数据，表示当前配置所属的 chart 信息
  # 此处数据用于存储模版最原始的信息，不随 Chart.yaml 的改变而改变
  _metadata:
    # chart 原始名称
    name: string
    # chart 原始版本
    version: string
    # chart 原始描述
    description: string
  # 分组 key ，该 key 可以是任意名称，但不能以 _ 开头
  group:
    # 类型 key ，这些 key 表示一个特定的类型，在下文中声明
    type:
      # 实例 key ，这些 key 作为父级 type 的一个实例，可以有两种表示形式
      # 1. 实例为一个对象，该对象的字段由 type 决定
      # 2. 实例为一个数组，该数组内可以有多个对象，对象的字段由 type 决定
      instance1:
        field1: value1
        field2: value2
      instance2:
        - field1: value1
          field2: value2
# 子模版的配置 key
chartX:
  # 子模版 chartX 的顶级配置，其结构与上面的 _config 相同
  _config:
  ......
```
在一个配置文件中，所有以 _ 开头的字段均有特殊含义，因此用于一般用途的 key 不能以 _ 开头。  
一般用途的 key 包括：
- 分组名称：可以自定义，建议只包含小写字母和数字
- 类型名称：不能自定义，必须符合下文中的类型名称
- 实例名称：可以自定义，建议只包含小写字母和数字
- 字段名称: 不能自定义，必须符合特定类型的字段名称

特殊字段包括：
- `_hidden`：一个字符串 map ，用于存储一个 type 中字段是否隐藏的映射，如果字段在 map 中不存在则视为 false
- `_readonly`：一个字符串 map ，用于存储一个 type 中字段是否只读的映射，如果字段在 map 中不存在则视为 false
- `_alias`：一个字符串 map ，用于存储一个 type 中字段名称与别名的映射，如果字段在 map 中不存在则视为使用字段名

### 类型定义
#### 类型： containers
```yaml
# 镜像路径
image: string
# 是否使用特权模式，默认值为 false
privileged: bool
# 镜像 pull 策略，可选值为：
# PullIfNotPresent
# Always
pullPolicy: string
```

#### 类型： envs
```yaml
# 环境变量名称
name: string
# 环境变量值
value: string
```

#### 类型： volumes
当应用需要挂载数据卷的时候，需要使用当前类型。
```yaml
# 数据卷名称，PVC 名称
name: string
# 数据卷是否只读，默认为 false
readonly: bool
# 挂载路径
mountPath: string
# 存储空间最小值，例如 "10Gi"
storageRequest: string
```

#### 类型： resources
```yaml
# cpu 资源请求值，即所需最小 cpu 资源。例如"100m"
cpuRequest: string
# cpu 资源上限值，即所能请求的最大 cpu 资源。例如"1000m"
cpuLimit: string
# 内存资源请求值，即所需最小内存资源。例如"128Mi"
memoryRequest: string
# 内存资源上限值，即所能请求的最大内存资源。例如"1Gi"
memoryLimit: string
```

#### 类型： services
当一个应用需要对外提供服务时，需要使用 services 类型暴露内部服务。
服务可以以两种形式暴露给外部：
- ClusterIP：使用该形式暴露的服务，其它应用可以通过服务名访问当前服务
- NodePort：使用该形式暴露的服务，其它应用可以通过节点 IP 访问当前服务
```yaml
# 服务名称，填写服务名称时最好是 应用名称+服务名称 的形式，防止服务名称冲突
name: string
# 通信协议，可选值为：
# TCP
# UDP
protocol: string
# 服务端口，表示外部应用访问当前服务需要使用的端口
port: string
# 节点端口，表示集群外部应用访问当前服务需要使用的端口
# 该值可以为空字符串表示不需要暴露节点端口
# 该端口值的默认范围为 [30000,32767]
nodePort: string
# 应用端口，表示当前应用使用的真实端口
targetPort: string
```

#### 类型：files
当需要配置一个完整的文件的时候，使用该类型暴露文件信息。
```yaml
# 文件路径
file: string
# 文件内容
value: string
```
