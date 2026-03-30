# LibraryBasket（无需本地 Theos）

这是一个 rootless / RootHide 用的 Theos tweak 工程骨架，用来在桌面插入一个“伪 App 资源库收纳筐”。

## 你现在没有 Theos 环境也能编译

### 方法 1：GitHub Actions 在线编译
1. 新建一个 GitHub 仓库。
2. 把这个文件夹里的所有文件上传到仓库根目录。
3. 打开仓库的 **Actions**。
4. 运行 **Build LibraryBasket**。
5. 编译完成后，在 Artifacts 里下载 `LibraryBasket-deb`。

这个 workflow 会自动安装 Theos，然后执行：

```bash
make package FINALPACKAGE=1
```

生成的 `.deb` 在：

```text
packages/
```

## 安装到手机
把生成的 `.deb` 传到手机后，可以用：
- Sileo / Zebra 直接安装
- 或终端：

```bash
dpkg -i /path/to/xxx.deb
sbreload
```

## 示例配置文件
把 `com.buzichi.librarybasket.plist` 放到：

```text
/var/jb/var/mobile/Library/Preferences/com.buzichi.librarybasket.plist
```

## 当前状态
这是 MVP：
- 桌面第一页左上角插入一个“社交”收纳筐
- 点击弹自定义面板
- 面板按 bundle id 列出 App
- 尝试用 `LSApplicationWorkspace` 启动 App

## 注意
- 不同 iOS 版本里 SpringBoard 私有类可能有偏差，首次编译后可能还要微调。
- 当前预览图还是占位块，不是真图标。
- 当前位置写死在第一页左上角，后续可再做网格定位和偏好设置。
