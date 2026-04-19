# nosleepclub

合盖不休眠，不需要外接显示器，不需要 HDMI 欺骗器。

`nosleepclub` 通过创建虚拟屏幕让 macOS 以为接了外接显示器，合上盖子后进入 clamshell 模式而不是休眠。

## 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/haoxli0412-spec/nosleepclub/main/install.sh | bash
```

安装完直接用：

```bash
nosleepclub
```

## 使用方法

```bash
# 启动（合盖不休眠）
nosleepclub

# 自定义分辨率
nosleepclub -w 2560 -h 1440

# HiDPI（Retina）模式
nosleepclub --hidpi

# 停止 — 按 Ctrl+C
```

### 后台运行

```bash
nosleepclub &          # 后台启动
pkill -f nosleepclub   # 停止
```

### 验证是否生效

```bash
# 查看虚拟屏幕
system_profiler SPDisplaysDataType | grep -A3 "nosleepclub"

# 查看防睡眠状态
pmset -g assertions | grep -E "PreventUserIdle|PreventSystem"
```

正常会看到：
- `nosleepclub Virtual Display: 1920 x 1080`
- `PreventUserIdleDisplaySleep = 1`
- `PreventUserIdleSystemSleep = 1`
- `PreventSystemSleep = 1`

## 系统要求

- macOS 14 (Sonoma) 或更高版本
- Apple Silicon 或 Intel Mac
- **必须接上电源**（macOS clamshell 模式的硬件要求）

## 原理

```
nosleepclub
├── 创建虚拟屏幕（CGVirtualDisplay API）
│   └── macOS 认为接了外接显示器
├── 运行 caffeinate -d -i -s
│   ├── -d: 阻止显示器休眠
│   ├── -i: 阻止空闲休眠
│   └── -s: 阻止系统休眠
└── 合盖 → clamshell 模式（不休眠）
    ├── 网络保持连接
    ├── 下载继续
    └── 进程继续运行
```

## 卸载

```bash
rm /usr/local/bin/nosleepclub
```

## 常见问题

**需要外接显示器或 HDMI 欺骗器吗？**
不需要。nosleepclub 用软件虚拟屏幕替代了物理设备。

**不接电源可以吗？**
不可以。macOS 要求接电源才能进入 clamshell 模式，这是硬件限制，任何软件都绕不过。

**虚拟屏幕会出现在系统设置里吗？**
会，在 设置 → 显示器 里可以看到 "nosleepclub Virtual Display"。

**安全吗？**
安全。虚拟屏幕在内存中创建，退出 nosleepclub 就自动移除。不修改系统文件，不安装内核扩展。

**支持 Intel Mac 吗？**
理论上支持所有运行 macOS 14+ 的 Mac，目前仅在 Apple Silicon (M4 Pro) 上测试过。

## 许可证

MIT
