# zig-demo

Zig 学习示例仓库。

本仓库包含一个用来演示 `std.http.Client` 的示例程序，示例代码位于 `fetch/` 目录：

- `fetch/main.zig` - 一个可运行的 HTTP 请求演示程序，向 `https://httpbin.org/get` 发送 GET 请求并打印状态与响应体。
- `fetch/fetch_test.zig` - 与示例相关的测试（可在本地运行）。

快速上手

1. 格式检查与格式化

```bash
zig fmt --check .
```

2. 语法检查（AST 检查）

```bash
zig ast-check fetch/main.zig
```

3. 构建并运行示例

```bash
zig build-exe fetch/main.zig
./fetch
# 或者直接运行
zig run fetch/main.zig
```

4. 运行测试

```bash
zig test fetch/fetch_test.zig
```

说明

- 我们把演示程序放在 `fetch/` 下，便于添加更多与 HTTP 请求、测试和模拟服务器相关的代码。
- 如果需要将示例扩展为流式读取或使用 mock server，建议在 `fetch/` 下添加相应测试与辅助文件。

贡献

欢迎提交 PR 或 issue。请在修改后运行 `zig fmt`, `zig ast-check`, `zig build-exe` 和 `zig test` 来确保变更正确。
