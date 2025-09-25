# zig-demo
ziglang 学习demo

这个项目包含了使用 Zig 语言的各种学习示例。

## 项目结构

- `src/fetch/` - HTTP 客户端库，包含对 httpbin.org 的各种请求实现
- `src/main.zig` - 主程序入口
- `build.zig` - Zig 构建配置

## HTTP Fetch 模块

`fetch` 目录包含了一个完整的 HTTP 客户端实现，支持：

### 功能特性
- 支持所有主要的 HTTP 方法 (GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS)
- JSON 请求/响应处理
- 自定义请求头支持
- 表单数据编码
- URL 编码工具
- 基础认证和 Bearer Token 认证
- 响应缓存
- 请求限流
- 重试机制
- 完整的错误处理

### HTTPbin.org 端点示例
项目包含了对 https://httpbin.org/ 网站各种端点的实现示例：

- `/get` - GET 请求和查询参数
- `/post` - POST 请求（JSON 和表单数据）
- `/put` - PUT 请求（JSON 数据）
- `/delete` - DELETE 请求
- `/patch` - PATCH 请求（JSON 数据）
- `/headers` - 自定义请求头检查
- `/user-agent` - User Agent 检查
- `/basic-auth/{user}/{passwd}` - 基础认证
- `/bearer` - Bearer Token 认证
- `/cookies/*` - Cookie 处理
- `/redirect/{n}` - 重定向处理
- `/status/{code}` - HTTP 状态码
- `/json` - JSON 响应解析
- `/response-headers` - 响应头检查

## 构建和运行

```bash
# 构建项目
zig build

# 运行示例
zig build run

# 运行测试
zig build test

# 只运行 fetch 模块测试
zig build test-fetch
```

## 使用示例

```zig
const std = @import("std");
const fetch = @import("fetch/mod.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = fetch.HttpClient.init(allocator);
    defer client.deinit();

    // 简单的 GET 请求
    var response = try client.get("https://httpbin.org/get", null);
    defer response.deinit();
    
    std.log.info("状态码: {}, 响应体: {s}", .{ response.status_code, response.body });
}
```

详细的使用文档请参考 `src/fetch/README.md`。
