# clone-no-marker.ps1 使用说明

<!-- 需要将以下所有的 clone-no-marker-usage 修改为 当前仓库 名称-->
<p align="center">
  <a href="https://wakatime.com/@marlin-phone/projects/xzabzjqwqe"> <!-- 这里需要去 wakatime 申请新的仓库徽章进行替换 -->
    <img src="https://wakatime.com/badge/user/72f7b5ae-3c4b-48e8-a41a-2f941eeb7e9d/project/7a20ea55-adfa-40a9-ae88-91218eb8849c.svg" alt="wakatime"/>
  </a>
  <img src="https://img.shields.io/github/last-commit/marlin-phone/clone-no-marker-usage?logo=github&color=success" alt="last commit"/>
  <img src="https://img.shields.io/github/commit-activity/w/marlin-phone/clone-no-marker-usage" alt="commit activity"/>
  <img src="https://visitor-badge.laobi.icu/badge?page_id=marlin-phone.clone-no-marker-usage" alt="visitors"/> 
  <img src="https://img.shields.io/github/languages/top/marlin-phone/clone-no-marker-usage?logo=c%2B%2B&logoColor=white" alt="top language"/>
  <img src="https://img.shields.io/github/license/marlin-phone/clone-no-marker-usage?cache=bust1" alt="license"/>
</p>


这是一个 PowerShell 脚本，用于克隆 GitHub 仓库并创建一个没有"生成自"标记的新仓库。

## 功能特点

- 克隆源仓库（仅最新一次提交，速度快）
- 在 GitHub 上创建新的空仓库
- 推送代码到新仓库（创建独立提交，无历史记录）
- 不会显示"生成自"标记
- 支持创建公开或私有仓库
- 可选：将本地目录与远程仓库绑定

## 使用前提

1. 安装 [GitHub CLI](https://cli.github.com/)
2. 使用以下命令登录到 GitHub：
   ```bash
   gh auth login
   ```

## 脚本参数

| 参数 | 是否必需 | 描述 | 默认值 |
|------|---------|------|--------|
| `-src` | 是 | 源仓库路径，格式：`用户名/仓库名` | 无 |
| `-newName` | 是 | 新仓库名称 | 无 |
| `-visibility` | 否 | 仓库可见性，可选值：`public` 或 `private` | `public` |
| `-bindLocal` | 否 | 开关参数，用于将本地目录与远程仓库绑定 | 未设置 |

## 使用方法

### 1. 基本用法（原始行为）

```powershell
./clone-no-marker.ps1 -src "用户名/源仓库名" -newName "新仓库名"
```

### 2. 创建私有仓库

```powershell
./clone-no-marker.ps1 -src "用户名/源仓库名" -newName "新仓库名" -visibility "private"
```

### 3. 将本地目录与远程仓库绑定

```powershell
./clone-no-marker.ps1 -src "用户名/源仓库名" -newName "新仓库名" -bindLocal
```

### 4. 绑定本地目录并创建私有仓库

```powershell
./clone-no-marker.ps1 -src "用户名/源仓库名" -newName "新仓库名" -visibility "private" -bindLocal
```

## 使用示例

### 示例 1：创建公开仓库
```powershell
./clone-no-marker.ps1 -src "octocat/Hello-World" -newName "my-hello-world"
```

### 示例 2：创建私有仓库
```powershell
./clone-no-marker.ps1 -src "octocat/Hello-World" -newName "my-private-repo" -visibility "private"
```

### 示例 3：从模板创建项目并绑定本地目录
```powershell
./clone-no-marker.ps1 -src "github/gitignore" -newName "my-project" -bindLocal
```

### 示例 4：创建私有仓库并绑定本地目录
```powershell
./clone-no-marker.ps1 -src "Marlin-Phone/clone-no-marker-usage" -newName "my-template-project" -visibility "private" -bindLocal
```

## 注意事项

1. 确保你有足够的权限在 GitHub 上创建仓库
2. 新仓库名必须在你的账户中唯一
3. 脚本只会克隆源仓库的最新一次提交，不会包含完整的历史记录
4. 在新仓库中会创建一个独立的初始提交
5. 如果执行过程中出错，脚本会尝试清理临时文件
6. 执行完成后，你可以在 GitHub 上访问新创建的仓库

## 本地绑定模式说明

当使用 `-bindLocal` 参数时，脚本会：

1. 在当前目录下创建一个名为 `newName` 的新目录
2. 初始化一个新的 Git 仓库
3. 克隆源仓库的最新文件到新目录
4. 创建 GitHub 远程仓库
5. 将本地仓库与远程仓库绑定
6. 推送初始提交到远程仓库

这使得你可以在本地立即开始工作，而不需要额外的克隆步骤。

## 常见问题和解决方案

### 1. "GitHub CLI 未安装" 错误
确保已安装 GitHub CLI 并将其添加到系统 PATH 中。

### 2. "未登录到 GitHub" 错误
确保已使用 `gh auth login` 登录到 GitHub。

### 3. "无法提取 GitHub 用户名" 错误
这通常是因为 GitHub CLI 的输出格式发生了变化。请确保使用最新版本的 GitHub CLI。

### 4. "克隆仓库失败" 错误
检查源仓库是否存在且你有访问权限。

### 5. "创建仓库失败" 错误
这可能是因为仓库名已存在或你没有权限创建仓库。请尝试使用不同的仓库名。

### 6. "推送失败" 错误
检查网络连接和 GitHub 权限设置。

### 7. "目录已存在" 错误
当使用 `-bindLocal` 参数时，如果目标目录已经存在同名文件夹，脚本会报错。请删除或重命名现有目录后重试。

### 8. "远程仓库已存在" 错误
如果 GitHub 上已经存在同名仓库，脚本会报错。请使用不同的仓库名或删除 GitHub 上的现有仓库。

## 故障排除

如果遇到问题，请按以下步骤进行排查：

1. 检查 GitHub CLI 是否正确安装和配置
2. 确认你已登录到正确的 GitHub 账户
3. 验证源仓库是否存在且可访问
4. 确保新仓库名在你的账户中是唯一的
5. 检查网络连接是否正常
6. 如果使用 `-bindLocal` 参数，确保目标目录不存在同名文件夹
7. 查看错误信息，根据具体提示进行处理

## 错误处理机制

脚本包含完善的错误处理机制：

- **预检检查**：在执行操作前检查必要的条件（如 GitHub CLI 安装、登录状态等）
- **中间状态清理**：如果在执行过程中出现错误，脚本会尝试清理已创建的临时文件和目录
- **详细错误信息**：提供清晰的错误信息，帮助用户快速定位问题
- **原子操作**：尽可能确保操作的原子性，避免部分完成的状态

## 许可证

此脚本为开源软件，遵循 MIT 许可证。