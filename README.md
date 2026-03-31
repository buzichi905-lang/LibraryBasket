# LibraryBasket Enhanced

这个版本在原骨架基础上补了三件事：

1. 桌面显示：按 pageIndex + slotIndex 把收纳筐显示在桌面网格里
2. 手势触发：
   - 点按收纳筐：打开面板
   - 长按收纳筐：编辑标题 / App 列表 / 删除
   - 双击桌面空白处：新建收纳筐
   - 长按桌面空白处 1 秒：显示手势说明
3. 收纳逻辑：
   - 收纳筐内容保存到 `/var/jb/var/mobile/Library/Preferences/com.buzichi.librarybasket.plist`
   - 可直接编辑 bundleID 列表并持久化

## 使用方式

- 安装后 respring
- 在桌面空白处双击两下，创建新的收纳筐
- 长按收纳筐，修改标题和 bundleID 列表
- 点按收纳筐，打开面板并启动 App

## bundleID 示例

- 微信：`com.tencent.xin`
- Safari：`com.apple.mobilesafari`
- 设置：`com.apple.Preferences`
- 信息：`com.apple.MobileSMS`

## 注意

当前版本的“收纳逻辑”是手动维护 bundleID 列表，不是读取系统 App 资源库的原生分类结果。
