### 背景
鉴于iOS10.3的beta，当APP被卸载之后，如果没有系统会删除APP keychain存储的数据. 如果使用keychain group时，只有当这个group中所有的APP被卸载之后，才会删除这个group的所有keychain 数据（已测试）
但是iOS10.3 正式版本，并没有包括这个新特性（在10.3.2上已测试）

在iOS10之后，系统新增了一个公共group *kSecAttrAccessGroupToken*， 可以使用这个group进行存储必要的数据，但是这个存在一定的安全问题，所有的APP都有访问这个公共group的权限。

### 需求
项目中有需求，需要跟踪用户，给特定的设备设置一定的权限，所有需要标识用户设备。


### 实现想法
鉴于我们APP只是标识用户手机，那么可以生成一个设备id 存储在这两个地方，APP独有的keychain，公共group的keychain
逻辑如下：

获取逻辑：
1. 先从APP独有keychain中获取
2. 如果没有，则看是否系统版本是否是10及以上
3. 如果是，则从公共group中获取deviceID
4. 都没有，则生成一个deviceID，保存device ID 到这两个地方。

生成存储逻辑：
1. 如果APP可以使用广告IDFA，则使用IDFA进行跟踪
2. 用户未开启，或者APP未接入广告，则使用系统生成UUID

流程图如下：
[获取DeviceID逻辑流程图](https://github.com/loupman/PLKeychainHelper/blob/master/fetch_device_id.png?raw=true)
[生成DeviceID逻辑流程图](https://github.com/loupman/PLKeychainHelper/blob/master/generate_device_id.png?raw=true)
