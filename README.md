[![noTunes Logo](/screenshots/app-icon.png)](https://github.com/tombonez/noTunes)

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/tombonez/notunes)](https://github.com/tombonez/noTunes/releases/latest)
[![GitHub all releases](https://img.shields.io/github/downloads/tombonez/notunes/total)](https://github.com/tombonez/noTunes/releases)
[![GitHub](https://img.shields.io/github/license/tombonez/notunes)](https://github.com/tombonez/noTunes/blob/master/LICENSE)
[![GitHub Sponsors](https://img.shields.io/badge/sponsor-tombonez-ec5cc7.svg)](https://github.com/sponsors/tombonez)

# noTunes

noTunes 是一款 macOS 应用，用于阻止 iTunes 或 Apple Music 启动。

启动 noTunes 后，iTunes / Music 将无法打开。例如蓝牙耳机重新连接时就不会再弹出 Music。

左键点击菜单栏图标即可开关此功能。

## 安装

### 直接下载

[noTunes-3.5.zip](https://github.com/tombonez/noTunes/releases/download/v3.5/noTunes-3.5.zip)

### Homebrew

```bash
brew install --cask notunes
```

## 使用说明

### 设置开机启动

右键或 Control + 点击菜单栏图标，勾选「登录时启动」。

若系统要求授权，请在 **系统设置 → 通用 → 登录项** 中确认允许 noTunes。

#### 手动设置（Ventura 及更新版本）：

1. 打开「系统设置」
2. 选择「通用」
3. 选择「登录项」
4. 在「登录时打开」下方点击 +，选择 noTunes

#### Ventura 之前：

打开「系统偏好设置」→「用户与群组」。在当前用户下选择「登录项」，点击左下角锁图标并输入密码以允许更改。在主面板点击 +，找到并添加 noTunes。

### 开关 noTunes 功能

左键点击菜单栏图标，可在启用 / 停用状态间切换。

**启用（阻止 iTunes / Music 打开）**

![noTunes Enabled](/screenshots/menubar-enabled.png)

**停用（允许 iTunes / Music 打开）**

![noTunes Disabled](/screenshots/menubar-disabled.png)

### 隐藏菜单栏图标

右键或 Control + 点击菜单栏图标，选择「隐藏图标」。

### 恢复菜单栏图标

[退出 noTunes](#退出-notunes) 后，在终端执行以下命令，再重新打开应用：

```bash
defaults delete digital.twisted.noTunes
```

### 退出 noTunes

可通过以下方式退出：

**菜单栏图标可见时**

右键或 Control + 点击菜单栏图标，选择「退出」。

**菜单栏图标已隐藏时**

在「活动监视器」中退出，或在终端执行：

```bash
osascript -e 'quit app "noTunes"'
```

### 设置 iTunes / Apple Music 的替代应用

将下面命令中的 `YOUR_MUSIC_APP` 替换为你的音乐应用名称：

```bash
defaults write digital.twisted.noTunes replacement /Applications/YOUR_MUSIC_APP.app
```

之后当 iTunes / Music 试图启动时，会改为打开 `/Applications/YOUR_MUSIC_APP.app`。

也可以用来打开网站，例如 YouTube Music：

```bash
defaults write digital.twisted.noTunes replacement https://music.youtube.com/
```

取消替代应用：

```bash
defaults delete digital.twisted.noTunes replacement
```

## 打包 DMG

默认打 Universal；传入 `arm` 或 `intel` 可打单架构 DMG：

```bash
./scripts/package-dmg.sh            # installers/noTunes-<VERSION>-universal.dmg
./scripts/package-dmg.sh arm        # installers/noTunes-<VERSION>-arm.dmg
./scripts/package-dmg.sh intel      # installers/noTunes-<VERSION>-intel.dmg
```

## 支持

如果喜欢这个项目，可以通过 [GitHub Sponsors](https://github.com/sponsors/tombonez) 支持原作者 🩷

## 许可证

代码基于 [MIT License](https://github.com/tombonez/notunes/blob/master/LICENSE) 开源。
