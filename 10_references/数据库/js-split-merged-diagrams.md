# js-split-merged 插件架构分析图表

## 1. 系统宏观架构图 (System Architecture Panorama)

```mermaid
graph TD
    subgraph Host[SillyTavern Host Environment]
        HostEvents[事件系统 (Event Source)]
        HostAPI[SillyTavern API]
        HostDOM[DOM (Input/Toastr)]
        HostHistory[聊天记录 (Chat History)]
    end

    subgraph Plugin[js-split-merged Plugin]
        Core[核心控制器 (main-initialize.js)]
        
        subgraph DataLayer[数据层 (Data Layer)]
            MemStore[内存状态 (currentJsonTableData_ACU)]
            StorageAdapter[存储适配器 (storage.js)]
            SchemaDef[Schema 定义 (template.js)]
        end
        
        subgraph LogicLayer[逻辑层 (Logic Layer)]
            Planner[剧情规划器 (optimization.js)]
            Updater[自动更新流水线 (processor.js)]
            LoopEngine[时钟循环 (loop.js)]
        end
        
        subgraph ViewLayer[表现层 (View Layer)]
            Visualizer[可视化编辑器 (Visualizer)]
            ToastMgr[消息提示 (Toastr Wrapper)]
        end
    end

    HostEvents -- "CHAT_CHANGED / GENERATION_ENDED" --> Core
    Core -- 调度 --> Planner
    Core -- 调度 --> Updater
    
    Planner -- 读取 --> MemStore
    Updater -- 读取/写入 --> MemStore
    
    Updater -- "Metadata Update" --> HostHistory
    HostHistory -- "Load Snapshot" --> MemStore
    
    Visualizer -- "Render" --> HostDOM
    Visualizer -- "Edit" --> MemStore
    
    LoopEngine -- "Trigger Generate" --> HostAPI
```

## 2. 数据流向与状态同步 (Data Flow & Synchronization)

该图展示了插件如何利用 Chat History 实现数据的"时间旅行"式持久化。

```mermaid
sequenceDiagram
    participant User
    participant UI as Visualizer UI
    participant Mem as In-Memory State
    participant Logic as Update Processor
    participant History as Chat History (SillyTavern)

    Note over User, History: 1. 数据加载流程 (Load)
    User->>History: 切换聊天 (Load Chat)
    History->>Mem: 扫描最近的消息 Metadata
    Mem->>Mem: 合并快照 (Merge Snapshot)
    Mem->>UI: 渲染表格 (Render)

    Note over User, History: 2. 数据更新流程 (Update)
    Logic->>Logic: 生成新数据 (LLM Output)
    Logic->>Mem: 更新内存状态
    Logic->>History: 查找当前最新消息 (Latest Msg)
    Logic->>History: 将新状态附加为 metadata (TavernDB_ACU_IsolatedData)
    Note right of History: 数据被"冻结"在该消息上<br/>切回此消息时数据自动回滚

    Note over User, History: 3. 可视化编辑 (Edit)
    User->>UI: 修改单元格
    UI->>Mem: 实时更新内存
    User->>UI: 点击保存
    UI->>History: 触发全量数据回写 (Save to History)
```

## 3. 剧情推进流水线 (Plot Orchestration Pipeline)

展示 MCTS-like 的规划与执行流程。

```mermaid
sequenceDiagram
    participant User
    participant Hook as TavernHelper Hook
    participant Planner as 剧情规划器
    participant LLM as LLM API
    participant ST as SillyTavern Core

    User->>Hook: 发送消息
    Hook->>Hook: 拦截请求 (Intercept)
    
    rect rgb(240, 248, 255)
        Note right of Hook: 规划阶段 (Planning Phase)
        Hook->>Planner: 启动规划
        Planner->>LLM: 请求剧情大纲 (Silent Call)
        LLM-->>Planner: 返回 <thought> + <plot>
        Planner->>Planner: 验证回复 (Check Length/Safety)
        
        alt 验证失败
            Planner->>Planner: 重试 (Retry Loop)
        else 验证成功
            Planner->>Hook: 返回注入指令 (System Directive)
        end
    end
    
    Hook->>ST: 发送修改后的 Prompt (User Msg + Plot Directive)
    ST->>LLM: 正式生成回复
    LLM-->>User: 返回最终剧情
```
