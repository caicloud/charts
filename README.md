# Chart 模版配置规范定义（v1.0.0）

### 目录
- [概述](#概述)
- [基础结构描述](#基础结构描述)
- [配置控制器定义](#配置控制器定义)
  - [类型：controller](#类型controller)
    - [controller：Deployment](#controllerdeployment)
    - [controller：StatefulSet](#controllerstatefulset)
    - [controller：DaemonSet](#controllerdaemonset)
    - [controller：Job](#controllerjob)
    - [controller：CronJob](#controllercronjob)
  - [类型：schedule](#类型schedule)
  - [类型：pod](#类型pod)
  - [类型：initContainer，container](#类型initcontainercontainer)
    - [probe：liveness，readiness](#probelivenessreadiness)
    - [handler：liveness，readiness，postStart，preStop](#handlerlivenessreadinesspoststartprestop)
      - [method：EXEC](#methodexec)
      - [method：HTTP](#methodhttp)
      - [method：TCP](#methodtcp)
  - [类型：volume](#类型volume)
    - [source：Dynamic，Dedicated](#sourcedynamicdedicated)
    - [source：Static](#sourcestatic)
    - [source：Scratch](#sourcescratch)
    - [source：Config，Secret](#sourceconfigsecret)
    - [source：HostPath](#sourcehostpath)
    - [source：Glusterfs](#sourceglusterfs)
  - [类型：service](#类型service)
  - [类型：config](#类型config)
  - [类型：secret](#类型secret)
- [一个配置文件的例子](#一个配置文件的例子)

### 概述
规范主要用于定义 Chart 配置文件 values.yaml 的逻辑结构和类型。  
我们将一个 Chart 包含的内容定义为一个应用，一个应用通常包含 Pod Controller，Service，Config，Volume 四块主要内容：
- Pod Controller：Deployment，StatefulSet，DaemonSet，Job，CronJob
- Service：Service
- Config：ConfigMap，Secret
- Volume：PVC，ConfigMap，Secret，EmptyDir

上述的对应关系并没有包含所有的 Kubernetes 资源，即我们认为其他资源是与应用是弱/无耦合的。  
并且其中 ConfigMap，Secret 也不是由 Chart 主动创建的，而是应当在应用创建之前就应该在集群中存在，并由应用引用，产生单向依赖。

### 基础结构描述
配置文件使用 yaml 格式，并且在实际使用中转换为 json 格式。  
标准配置文件结构如下：

```yaml
# 顶级配置 key ，固定为 _config
_config: 
  # 在配置文件中，所有以 _ 开头的字段用于存储特殊信息。  
  # 模板元数据，表示当前配置所属的 Chart 信息，此处数据用于存储模版最原始的信息
  _metadata:
    name: string          # Chart 创建时的名称，不随 Chart 更新而更新
    version: semvar       # Chart 创建时的版本号，不随 Chart 更新而更新
    description: string   # Chart 创建时的描述，不随 Chart 更新而更新
    template:             # Chart 模板信息，为模板自动升级提供信息
      type: string        # Chart 模板类型
      version: semvar     # Chart 模板版本号
  # 配置控制器组，配置控制器组可以包含多个配置控制器
  # 此处的配置控制器与上面所描述的 Pod Controller 不同，此处的配置控制器具有如下等价关系：
  # 配置控制器 = 1个 Pod Controller 配置 +
  #             1个 调度 配置 +
  #             1个 容器组 配置 +
  #             0个或多个 初始化容器 配置 +
  #             1个或多个 基本容器 配置 +
  #             0个或多个 数据卷 配置 +
  #             0个或多个 服务 配置
  controllers:
  - type: string          # 指定控制器的类型，可以是 Deployment，StatefulSet，DaemonSet，Job，CronJob
    controller:           # 控制器信息，对应特定 type 的控制器信息
      ...
    schedule:             # 调度信息，用于控制容器组的调度
      ...
    pod:                  # 容器组信息，指定当前控制器下的所有容器（包括 initializers 和 containers）共享的设置内容
      ...
    initContainers:       # 初始化容器数组，可用于放置仅用于初始化阶段的容器，比如初始化数据
    - ...
    containers:           # 基本容器数组，用于放置真正执行工作的容器
    - ...
    volumes:              # 数据卷描述信息数组，这部分数据卷可以被多个容器共享访问
    - ...
    services:             # 服务信息数组，当前控制器内的容器需要暴露服务时，在这里添加服务。一个控制器可有多个服务
    - ...
    configs:              # 配置信息数组
    - ...
    secrets:              # 加密配置信息数组
    - ...
chartX:
  # 子模版 chartX 的配置，其结构与上面的 _config 相同
  _config:
    ...
```
`_metadata`仅仅用于描述模板的基本信息。
- name，version，description 用于描述 Chart 的原始信息。用于从配置直接创建 Chart。
- template 用于描述 Chart 的模板信息。主要用于实现 Chart 的创建和升级。template 发生功能变更后，可依据模板名称和版本号进行升级。

### 配置控制器定义

字段类型定义：

```
int:     整数
uint:    自然数
pint:    正整数
float:   实数
string:  字符串
bool:    布尔值，只能是 true 或 false
```
默认值声明方式：

```
类型(默认值)
int(-1)
uint(0)
pint(1)
float(3.14)
string("default value")
bool(true)
```
所有有默认值的字段都是 Optional 的。

#### 类型：controller

所有类型的 controller 共有字段如下：

```yaml
annotations:                           # 控制器附加信息,仅用于保存控制器额外信息
  - key: string                        # 键
    value: string                      # 值
```
key 必须符合如下要求：

```
1. `前缀/键`或者`键`，比如 `caicloud.io/apple`和`apple`
2. 前缀是域名形式，必须符合 DNS_SUBDOMAIN，即`(([A-Za-z0-9][-A-Za-z0-9]*)?[A-Za-z0-9]\.)*([A-Za-z0-9][-A-Za-z0-9]*)?[A-Za-z0-9]`
3. 键必须符合 ([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9]
```

##### controller：Deployment
```yaml
replica: uint(1)                       # 实例数量
strategy:                              # 实例滚动更新策略，两个选项不能同时为0
  unavailable: uint(0)                 # 最大不可用数量
  surge: uint(1)                       # 最大超量
ready: uint(0)                         # 实例从 Available 到 Ready 的最短时间
```
一个实例在运行时等价于一个容器组，可以通过 replica 指定需要的实例数量，即可在集群中同时跑多个实例。  
当实例的配置需要更新时，根据更新策略决定如何重启实例。unavailable 表明当前控制器可以先关闭多少个运行中的实例。surge 表示当前控制器可以在 replica 的基础上多创建多少个新的实例。即在滚动更新过程中，实例的数量可能在[max(replica-unavailable,0),replica+surge]区间。  

##### controller：StatefulSet
```yaml
replica: uint(1)                              # 实例数量
name: string("")                              # 实例前缀名
domain: string("")                            # 实例域名
strategy:                                     # 实例滚动更新策略
  type: string("RollingUpdate)                # 更新策略，只能为 RollingUpdate(滚动更新) 或者 OnDelete(删除时更新)
  rollingUpdate:                              # 滚动更新配置，只有当 RollingUpdate 时才可以此选项
    partition: uint(0)                        # 分段更新序号
podManagementPolicy: string("OrderedReady")   # Pod 管理策略, 只能为 OrderedReady 或 Parallel
```
指定 name 和 domain 后，可通过 name-序号.domain 的形式访问每个实例。
比如 replica = 2, name = "web", domain = "cluster", 那么同一个分区内可使用 web-0.cluster，web-1.cluster 访问两个实例，同时能够直接使用 cluster 访问任意一个实例（RoundRobin）。  
由于前缀名称和域名具有分区范围内的唯一性，因此同一个分区内的应用不能具有相同的 name 和 domain。同时由于 domain 能够被用于访问任意一个实例，因此也不能与同一分区下的 services 冲突。

##### controller：DaemonSet
```yaml
strategy:                              # 实例滚动更新策略，两个选项不能同时为0
  unavailable: pint(1)                 # 最大不可用数量
ready: uint(0)                         # 实例从 Available 到 Ready 的最短时间
```

##### controller：Job
```yaml                            
parallelism: pint(1)                   # 最大并行实例数量
completions: pint(1)                   # 总共需要完成的实例数量
active: uint(0)                        # 单个实例执行的最长时间，0表示不限制
```
一个任务可以同时执行多个实例，通过 parallelism 和 completions 可以控制任务是串行执行还是并行执行或是控制并行执行。  
- 串行：completions = n, parallelism = 1  即可让 n 个实例串行执行，只有前一个完成后下一个才会执行
- 并行：completions = n, parallelism >= n  即可让 n 个实例同时并行执行
- 控制并行：completions = n, parallelism = k, k < n 即可让 n 个实例同时只有 k 个在执行。其中一个实例完成才能让下一个实例开始执行

##### controller：CronJob
```yaml
rule: string                           # 定时规则，比如 "*/1 * * * *"
deadline: uint(0)                      # 任务启动超时时间
policy: string("Allow")                # 任务并发策略，Allow，Forbid，Replace
suspend: bool(false)                   # 是否暂停当前定时任务
history:                               # 任务执行历史保留选项
  success: uint(0)                     # 执行成功的任务保留数量
  fail: uint(0)                        # 执行失败的任务保留数量
parallelism: pint(1)                   # 最大并行实例数量
completions: pint(1)                   # 总共需要完成的实例数量
active: uint(0)                        # 单个实例执行的最长时间，0表示不限制
```
定时任务规则格式参考：https://en.wikipedia.org/wiki/Cron  
定时任务启动超时时间：
举个例子，定时任务设置在每天 8:00:00 执行一次，然后这个字段设置为 10 秒，那么在 8:00:00 - 8:00:10 这个期间内，如果发生了某个特殊的事情，比如 kubernetes 的 定时器 在 7:59:59 - 8:00:11 这个时间段内一直是崩溃的，那么这个定时任务的这一次触发就会被错过，然后就会在定时任务的失败任务数量上加1。  
定时任务使用一个 rule 来控制任务的执行。当一个任务未尚未完成，定时器又触发的时候通过 policy 来控制任务的执行方式：
- Allow：上次触发的任务和本次触发的任务一起执行
- Forbid：如果上次的任务尚未完成，那么跳过本次任务的执行
- Replace：取消上次的任务，并开始执行本次的任务

#### 类型：schedule
```yaml
scheduler: string("")                                  # 调度器名称，可选项为 空字符串，为空表示使用默认调度器
labels:                                                # 控制器及 容器组 标签
  string: string                                       # 这里的 key 在模板中自动加上前缀 `schedule.caicloud.io/`
affinity:                                              # 亲和性设置
  pod:
    type: string("Required")                           # 类型可以为 Required 或 Prefered
    terms:
    - weight: pint                                     # 权重，只有类型为 Prefered 时可以设置该字段，[1-100]
      topologyKey: string("kubernetes.io/hostname")    # 拓补域
      namespaces:                                      # 指定分区，不指定表示仅在当前分区
      - string                                       
      selector:                                        # 选择器，用于设置匹配的标签
        labels:                                        # 直接指定标签值
          string: string                               # 这里的 key 在模板中自动加上前缀 `schedule.caicloud.io/`
        expressions:                                   # 通过表达式查找标签
        - key: string                                
          operator: string                             # 操作符 In，NotIn，Exists，DoesNotExist
          values:                                      # 标签值列表
          - string                                   
  node:                                              
    type: string("Required")                           # 类型可以为 Required 或 Prefered
    terms:
    - weight: 10                                       # 权重，只有类型为 Prefered 时可以设置该字段，[1-100]
      expressions:                                     # 通过表达式查找标签，表达式为 AND 表达式
      - key: string                                    # 这里的 key 不会自动加上前缀
        operator: string                               # 操作符 In，NotIn，Exists，DoesNotExist，Gt，Lt
        values:
        - string                                     
antiaffinity:                                        
  pod:                                                 # 反亲和性设置与亲和性设置相同
    ...                                              
tolerations:                                           # 节点容忍设置
- key: string                                          # 容忍的 Key
  operator: string                                     # 操作符 Exists，Equal
  value: string                                        # 值
  effect: string                                       # 容忍策略 NoScheduler，PreferNoScheduler，NoExecute
  tolerationSeconds: uint                              # 容忍时间 仅在 effect 为 NoExecute 时有效
```
topologyKey 具有如下值:

```
kubernetes.io/hostname
failure-domain.beta.kubernetes.io/zone
failure-domain.beta.kubernetes.io/region
```

拓补域用于定义一个节点集合。目前常用的拓补域的 key 有如上三种。拓补域与 Pod 的 亲和性/反亲和性 相关。  
一个拓补域至少有一个节点，所有的 亲和性/反亲和性 的权重计算都是在一个域中进行。  
比如有多个域，当一个 Pod 在调度时，调度器会根据 亲和性/反亲和性 的设置，在多个域中寻找一个权重最高的域，然后将 Pod 调度到该域中的一个节点上。  
`kubernetes.io/hostname`与其他两个稍有不同。这个 key 在每个节点上都有不同的值，也就是说，集群里的每个节点都构成了只有一个节点的域。  

容忍策略 NoExecute 尚未实现。

关于 Pod 和 Node 的 Label 前缀问题的说明：
1. Pod 在这里有默认前缀 `schedule.caicloud.io/`。也就是说在设置 Pod 的 标签 和 亲和性/反亲和性 的时候，都不需要在 key 中加上前缀。
2. Node 在这里都没有默认前缀，并且 Node 的 亲和性/容忍 设置中的 key 都不会自动加上某个特定的前缀。
出现这种设置的原因是 Pod 的 亲和性/反亲和性 设置都是在应用中可以定义的，因此在应用中可以规定这个统一前缀。  
而 Node 不归应用管理，因此不能确定 Node 中是否会使用前缀或使用多少个前缀。所以不对 Node 相关的 调度 设置设定统一的 key 前缀。


#### 类型：pod
```yaml
restart: string("Always")              # 重启策略，可以为 Always，OnFailure，Never
dns: string("ClusterFirst")            # DNS 策略，可以为 Default，ClusterFirstWithHostNet，ClusterFirst
hostname: string("")                   # 主机名
subdomain: string("")                  # 子域名
termination: uint(30)                  # 优雅退出时间
serviceAccountName: string("")         # ServiceAccount
host:
  network: bool(false)                 # 与主机共享 network namespace
  pid: bool(false)                     # 与主机共享 pid namespace
  ipc: bool(false)                     # 与主机共享 ipc namespace
hostAliases:                           # 向容器组的 /etc/hosts 文件添加条目
  - ip: string                         # IP 地址
    hostnames:                         # 主机名列表
    - string
securityContext:
  runAsNonRoot: bool(false)            # 是否以非 root 用户运行
annotations:                           # 容器组附加信息,仅用于保存容器组额外信息
  - key: string                        # 键
    value: string                      # 值

```
在 controller 类型为 Deployment 时，restart 只能为 Always。  
主机名和子域名构成 Pod 的访问域名：hostname.subdomain.namespace.svc.clusterdomain。  
容器组的 annotations 用于存放用于扩展容器组能力的额外信息。可以被其他组件读取和识别，实现其他功能。
key 的规范参考 [controller 的 annotations](#类型controller)


#### 类型：initContainer，container
```yaml
name: string("")                       # 容器名称
image: string                          # 镜像地址
imagePullPolicy: string(Always)        # 镜像拉取策略，可以设置为 Always，IfNotPresent
tty: bool(false)                       # 是否使用 tty
command:                               # 即 Docker EntryPoint
- string    
args:                                  # 即 Docker CMD
- string
workingDir: string("")                 # 工作目录
securityContext:
  privileged: bool(false)              # 是否启动特权模式
  capabilities:                        # POISX CAP
    add:                               # 添加 POISX CAP
    - string
    drop:                              # 移除 POISX CAP
    - string
ports:                                 # 容器端口
- port: pint(80)                       # 端口
  hostPort: pint(0)                    # 暴露到主机端口
  protocol: string("HTTP")             # 端口协议,可以是 HTTP，HTTPS，TCP，UDP
envFrom:                               # env from，来自 Config 或 Secret
- prefix: string("")                   # 所有来自 目标 的 key 都会加这个前缀
  type: string("Config")               # 配置来源，可以是 Config 或 Secret
  name: string                         # Config 或 Secret 的名称
  optional: bool(false)                # 是否可选，即目标不存在也就忽略而不是报错
downwardPrefix: string("")             # 默认环境变量前缀
env:                                   # env
- name: string                         # 环境变量名称
  value: string                        # 环境变量值
  from:                                # value 和 from 只能二选其一
    type: string("Config")             # 来源类型
    name: string                       # Config 或 Secret 的名称
    key: string                        # data 的 key
    optional: bool(false)              # 是否可选，即目标不存在也就忽略而不是报错
resources:                             # 资源限制
  requests:                            # 请求的资源下限
    cpu: string("100m")                # CPU 资源
    memory: string("100Mi")            # 内存资源
    storage: string("")                # 存储资源
    gpu: string("")                    # GPU 资源
  limits:                              # 请求的资源上限
    cpu: string("100m")                # CPU 资源
    memory: string("100Mi")            # 内存资源
    storage: string("")                # 存储资源
    gpu: string("")                    # GPU 资源
mounts:                                # 挂载数据卷位置
- name: string                         # 数据卷名称
  readonly: bool(false)                # 是否只读
  path: string                         # 挂载路径
  subpath: string("")                  # 挂载的数据卷子路径
  propagation: string("None")          # 挂载传播类型，可选项为 None，HostToContainer，Bidirectional
probe:                                 # 健康检查
  liveness:                            # 存活检查（参考 probe 设置）
    ...
  readiness:                           # 可读检查（参考 probe 设置）
    ...
lifecycle:                             # 生命周期（参考 handler 设置）
  postStart:                           # 启动后调用，调用失败则重启容器
    ...
  preStop:                             # 停止前调用，调用后无论成功失败都会终止容器
    ...
```
initContainer 不支持 readiness probe 和 lifecycle，因此在 initContainer 中不能设置这几项。  
initContainer 是串行执行的，一个成功后才能执行下一个。 
默认的环境变量包括：

- `POD_NAMESPACE`
- `POD_NAME`
- `POD_IP`
- `NODE_NAME`

可以通过 downwardPrefix 为上述环境变量增加前缀。比如 downwardPrefix 为 `ENV_` 时：`POD_NAMESPACE` 变为 `ENV_POD_NAMESPACE`。  

##### probe：liveness，readiness
```yaml
handler:                               # 调用 handler 检查方式
  ... 
delay: uint(0)                         # 从容器启动到发送健康检查请求的时间间隔（秒）
timeout: pint(1)                       # 单次请求的超时时间（秒）
period: pint(10)                       # 请求时间间隔（秒）
threshold:
  success: pint(1)                     # 连续多少次请求成功则认为健康
  failure: pint(3)                     # 连续多少次请求失败则认为不健康
```

##### handler：liveness，readiness，postStart，preStop
```yaml
type: string(HTTP)                     # handler 类型，可以为 HTTP，EXEC，TCP
method:                                # handler 方法
  ...
```

###### method：EXEC
```yaml
command:                               # 执行命令
- string
```

###### method：HTTP
```yaml
scheme: string(HTTP)                   # HTTP 或 HTTPS
host: string("")                       # Host 字段，默认是 pod ip, 如果只是想使用域名，请填在 headers 里面
port: pint                             # 容器端口
path: string                           # HTTP Path
headers:                               # 请求头
- name: string                         # Header 名称
  value: string                        # Header 值
```
对于 `host` 这个字段，在 kubernetes 官网的[解释](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/#configure-probes)里面说明，大部分情况下是用不上的，有一种情况是，如果你的 container 监听了 `127.0.0.1` 并且 pod 使用了 hostNetwork，则这个 `host` 需要修改成 `127.0.0.1` 。在其他通用的使用场景中，你的 container 里面提供了多个虚拟域名（如 nginx 反向代理)，那么你应该在 `headers` 里面设置 `Host` 的值，而不是使用 `host` 。

###### method：TCP
```yaml
port: pint                             # TCP 端口
```


#### 类型：volume
```yaml
name: string                           # 数据卷名称，在容器中被引用
type: string("Scratch")                # 可选项为 Dedicated，Dynamic，Static，Scratch，Config，Secret，HostPath。Dedicated 仅在控制器为 StatefulSet 时可用
source:                                # source 的设置与 type 有关
  ... 
storage:                               # 存储需求
  request: string("5Gi")               # 请求的最小存储容量
  limit: string("10Gi")                # 请求的最大存储容量
```

##### source：Dynamic，Dedicated
```yaml
    class: string                      # 存储方案名称
    modes:
    - string("ReadWriteOnce")          # 数据卷读写模式，可以为 ReadWriteOnce，ReadOnlyMany，ReadWriteMany
```
Dynamic 和 Dedicated 两种类型的数据卷实际上都是使用存储方案来实现，即通过创建 PVC 并关联 storage class。  
但是 Dynamic 只用于创建单一的 PVC，如果多个容器引用同一个 Dynamic，那么实际上多个副本是共享数据卷的（多副本时 mode 不能为 ReadWriteOnce）。  
Dedicated 类型仅用于 StatefulSet 类型的控制器。StatefulSet 会根据 Dedicated 的设置动态创建多个 PVC，并且每个 Pod 会绑定不同的 PVC，即每个 Pod 的数据卷是独立的。
这两种类型的数据卷在部署后，volume 中的所有字段值都不能进行更改。

##### source：Static
```yaml
    target: string                     # 已创建的数据卷名称
    readonly: bool(false)              # 是否以只读形式挂载
```
Static 类型的数据卷只能用于使用已经创建好数据卷（PVC）。

##### source：Scratch
```yaml
    medium: string("")                 # 存储介质，可以为 空字符串 或 Memory
```
Scratch 表示使用临时数据卷 EmptyDir。

##### source：Config，Secret
```yaml
    target: string                     # 已创建的 Config 或 Secret
    items:
    - key: string                      # 配置文件 data 中的 key
      path: string                     # 设置 key 对应的值在数据卷中的绝对路径
      mode: string("0644")             # 文件读写模式，如果这里为空则使用默认文件读写模式
    default: string("0644")            # 默认文件读写模式
    optional: bool(false)              # 是否允许指定的 Config 或 Secret 不存在
```
Config 和 Secret 表示使用 配置 或 秘钥 作为数据卷。能够指定 配置 和 秘钥 的多个 key 作为文件使用。

##### source：HostPath
```yaml
    path: string                       # 本地文件路径
```

##### source：Glusterfs
```yaml
    endpoints: string                  # glusterfs endpoints
    path: string                       # glusterfs volume path
    readonly: bool(false)              # 是否以只读形式挂载
```

#### 类型：service
```yaml
name: string                           # 服务名称
type: string(ClusterIP)                # 服务类型，可以是 ClusterIP，NodePort
export: bool(true)                     # 标记服务是否导出（在 Kubernetes 层面无效）
ports:
- protocol: string(HTTP)               # 端口协议，可以是 HTTP，HTTPS，TCP，UDP
  targetPort: pint                     # 容器端口
  port: pint                           # 服务端口
  nodePort: uint(0)                    # 节点端口，[30000,32767]
annotations:                           # 服务附加信息,仅用于保存服务额外信息
  - key: string                        # 键
    value: string                      # 值
```
服务可以以两种形式暴露给外部：
- ClusterIP：使用该形式暴露的服务，其它应用可以通过服务名访问当前服务
- NodePort：使用该形式暴露的服务，其它应用可以通过节点 IP 访问当前服务

服务类型为 NodePort 时，才可以设置 ports 中的 nodePort 字段。  
服务在部署后，服务名称不可变更。

#### 类型：config
```yaml
name: string                           # 配置名称
data:
- key: string                          # 键
  value: string                        # 值
```

#### 类型：secret
```yaml
name: string                           # 加密配置名称
type: string(Opaque)                   # 加密配置类型
data:
- key: string                          # 键
  value: string                        # 值，必须是原始值经过 base64 编码后的字符串
```

加密配置的类型包括：

- Opaque：默认加密配置类型，key 可以是任意有效的字符串
- kubernetes.io/service-account-token： ServiceAccount，key 包括
  - kubernetes.io/service-account.name
  - kubernetes.io/service-account.uid
  - token
  - kubernetes.kubeconfig
  - ca.crt
  - namespace
- kubernetes.io/dockercfg： Docker config，key 包括
  - .dockercfg
- kubernetes.io/dockerconfigjson： Docker config json，key 包括
  - .dockerconfigjson
- kubernetes.io/basic-auth： Basic auth，key 包括
  - username
  - password
- kubernetes.io/ssh-auth： SSH auth，key 包括
  - ssh-privatekey
- kubernetes.io/tls： TLS 证书密钥（PEM），key 包括
  - tls.crt
  - tls.key


### 一个配置文件的例子
```yaml
_config:
  _metadata:
    name: template
    version: 1.0.0
    description: "A basic template for application"
    creationTime: "2017-07-14 12:00:00"
    source: "/library/template/1.0.0"
    class: Default
    template:
      type: "template.caicloud.io/application"
      version: 1.0.0
  controllers:
  - type: StatefulSet
    controller:
      replica: 3
      name: "asda2222"
      domain: "asdas"
    schedule:
      labels:
        cpu: heavy
        io: heavy
      affinity:
        node:
          type: Prefered
          terms:
          - weight: 10
            expressions:
            - key: cpu
              operator: NotIn
              values:
              - heavy
              - midium
        pod:
          type: Required
          terms:
          - selector:
              labels:
                cpu: heavy
      antiaffinity:
        pod:
          type: Prefered
          terms:
          - weight: 10
            selector:
              expressions:
              - key: cpu
                operator: In
                values:
                - heavy
                - midium
    pod:
      host:
        network: true
    initContainers:
    - image: mysql-init:v1.0.0
      mounts:
      - name: db-volume
        path: /var/lib/mysql
      resources:
        requests:
          cpu: 100m
          memory: 100Mi
        limits:
          cpu: 100m
          memory: 100Mi
    containers:
    - image: mysql:v5.6
      ports:
      - protocol: TCP
        port: 3306
      mounts:
      - name: db-volume
        path: /var/lib/mysql
      - name: shared-volume
        path: /var/lib/logs
      envFrom:
      - type: Config
        name: someconfigmap
        prefix: XXXX_
        optional: false
      downwardPrefix: MY_ENV
      env:
      - name: XXSS_
        value: "sd"
      resources:
        requests:
          cpu: 100m
          memory: 100Mi
        limits:
          cpu: 100m
          memory: 100Mi
      probe:
        liveness:
          handler:
            type: HTTP
            method:
              port: 80
              path: /liveness
          delay: 10
        readiness:
          handler:
            type: EXEC
            method:
              command:
              - curl
              - http://localhost
          delay: 15
    volumes:
    - name: db-volume
      type: Dedicated
      source:
        class: hdd
        modes:
        - ReadWriteOnce
      storage:
        request: 5Gi
      propagation: None
    - name: shared-volume
      type: Dynamic
      source:
        class: ssd
        modes:
        - ReadWriteMany
      storage:
        request: 5Gi
        limit: 100Gi
    services:
    - name: mysql1
      type: ClusterIP
      export: true
      ports:
      - protocol: HTTP
        targetPort: 80
        port: 80
    - name: mysql2
      type: NodePort
      export: false
      ports:
      - protocol: HTTPS
        targetPort: 443
        port: 443
        nodePort: 31222
  - type: Deployment
    controller:
      replica: 1
    containers:
    - image: cargo.caicloudprivatetest.com/caicloud/simplelog
      mounts:
      - name: cfgvolume
        path: /etc/simplelog
      resources:
        requests:
          cpu: 100m
          memory: 100Mi
        limits:
          cpu: 100m
          memory: 100Mi
    services:
    - name: log1
      type: ClusterIP
      export: true
      ports:
      - protocol: HTTP
        targetPort: 80
        port: 80
    volumes:
      name: cfgvolume
      type: Config
      source:
        target: simplecfg
        items:
        - key: "config.yaml"
          path: "config.yaml"
    configs:
    - name: simplecfg
      data:
      - key: "config.yaml"
        value: |
          sync: "5m"
          deadline: "3h"
    secrets:
    - name: simplesecret
      data:
      - key: "encrypted.cfg"
        value: c3luYzogIjVtIgpkZWFkbGluZTogIjNoIgo=
subchart:
  _config:
    略
```
