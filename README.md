# AI 文档排版规范（Word）

统一管理 Codex 在 Windows、Ubuntu、macOS 生成 Word（.docx）时使用的排版规范。

## 文件说明

- [word_format.md](./word_format.md)：唯一正式规范（v1.2）。保留排版要求，默认后台生成，只做结构检查。
- [AGENTS.global-snippet.md](./AGENTS.global-snippet.md)：加入 Codex 全局 `AGENTS.md` 的规则示例。
- [setup_codex_word_standard.sh](./setup_codex_word_standard.sh)：Ubuntu/macOS 安装脚本。
- [setup_codex_word_standard.ps1](./setup_codex_word_standard.ps1)：Windows PowerShell 安装脚本。

## 一次性配置

下载或克隆本仓库后，在仓库目录中执行：

**Ubuntu / macOS**
```bash
bash setup_codex_word_standard.sh
```

**Windows PowerShell**
```powershell
powershell -ExecutionPolicy Bypass -File .\setup_codex_word_standard.ps1
```

脚本只修改当前电脑用户目录下的 `~/.codex/AGENTS.md` 和 `~/.codex/word_format.md`，并对已有 AGENTS 做备份；不会修改其他项目。

重新启动 Codex 会话后，可以直接说“按默认规范生成 Word”。Codex 应在生成前从 GitHub 读取最新版，网络失败时读取本地缓存并告知。

执行方式见 [规范开头](./word_format.md)：后台生成、基本结构检查后直接交付。字体、标题、表格等具体排版要求统一保留在规范中。

## 更新已有安装

重新执行安装脚本，会从同目录的 `AGENTS.global-snippet.md` 读取规则，替换 `AGENTS.md` 中 `WORD_STANDARD_START/END` 标记之间的旧内容，保留其他规则。实际发生修改时才备份；重复安装不会重复追加规则。标记损坏或重复时停止修改 `AGENTS.md` 并报错。

尚未发布到 GitHub 的本地修改，可显式预览安装：

```powershell
powershell -ExecutionPolicy Bypass -File .\setup_codex_word_standard.ps1 -UseLocalStandard
```

```bash
bash setup_codex_word_standard.sh --local
```

这两个选项只影响本次安装时的规范来源；之后生成文档仍按规则尝试读取 GitHub 最新规范。要让其他电脑也读取 v1.2，需要先发布仓库修改，再在那些电脑更新安装。仅修改本地仓库不会更新全局规则或 GitHub。

脚本支持隔离验证：PowerShell 用 `-ConfigDirectory <临时目录>`，Bash 用 `--config-dir <临时目录>`。验证安装不必修改真实 `~/.codex`。

## 回归验证

```bash
python -m unittest discover -s tests -v
```

测试只使用临时目录，覆盖首次安装、旧规则更新、重复安装、保留其他指令、异常标记保护及下载失败回退。Windows 测试 PowerShell；具备 Bash 的 POSIX 系统测试 Bash。缺少对应解释器时显示跳过，不宣称已通过。

**注意：** GitHub 仓库的文件更新不代表已经自动修改所有电脑上的 AGENTS.md。每台电脑需安装一次规则；Codex 必须有网络访问权限，才能每次拉取最新版。云端 Markdown 是排版要求，并不是已生成的 Word 模板。
