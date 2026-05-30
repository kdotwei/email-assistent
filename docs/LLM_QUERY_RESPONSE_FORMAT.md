# LLM Input / Output Contract — Notion Task Automation

This document defines what the LLM receives as input, what it must return as output, and the rules it must follow when mapping email data to Notion tasks.

---

## 1. What the LLM receives

The LLM receives a single JSON object with two parts: the database schema and the email to process.

```json
{
  "schema": {
    "database_name": "Tasks",
    "fields": [
      { "name": "Task Name", "type": "title", "required": true },
      {
        "name": "Status",
        "type": "status",
        "options": ["Not Started", "In Progress", "Done", "Cancelled"]
      },
      {
        "name": "Priority",
        "type": "select",
        "options": ["High", "Medium", "Low"]
      },
      { "name": "Due Date", "type": "date" },
      {
        "name": "Tags",
        "type": "multi_select",
        "options": [
          "notion",
          "collaboration",
          "updates",
          "admin",
          "engineering",
          "design",
          "marketing"
        ]
      },
      { "name": "Description", "type": "rich_text" },
      { "name": "Requestor", "type": "rich_text" },
      {
        "name": "Which Weekly?",
        "type": "formula",
        "note": "Auto-calculated, read-only"
      },
      {
        "name": "Created",
        "type": "created_time",
        "note": "Auto-set, read-only"
      }
    ]
  },
  "email": {
    "subject": "KdotWei is ready to collaborate with you on Notion Todos",
    "from": "KdotWei via Notion <notify@mail.notion.so>",
    "snippet": "View KdotWei's Todos page. KdotWei's Workspace · 1 member · Write, plan, organise.",
    "received_date": "2025-05-28",
    "labels": ["CATEGORY_UPDATES", "UNREAD"]
  }
}
```

### Schema field types

| Type               | Behaviour                                                                     |
| ------------------ | ----------------------------------------------------------------------------- |
| `title`            | Always required. Maps to the task name.                                       |
| `select`           | Single value. Must exactly match one of the provided `options`.               |
| `status`           | Same as `select`. Must exactly match one of the provided `options`.           |
| `multi_select`     | Array of strings. Each item must exactly match one of the provided `options`. |
| `date`             | ISO 8601 string: `YYYY-MM-DD`.                                                |
| `rich_text`        | Plain string. No formatting.                                                  |
| `formula`          | **Read-only. Never set this field.**                                          |
| `created_time`     | **Read-only. Never set this field.**                                          |
| `rollup`           | **Read-only. Never set this field.**                                          |
| `last_edited_time` | **Read-only. Never set this field.**                                          |

---

## 2. What the LLM must return

Respond with a **single valid JSON object only**. No markdown, no backticks, no explanation outside the JSON.

```json
{
  "task_name": "string — required",
  "fields": {
    "Status": "string — must match schema options exactly",
    "Priority": "string — must match schema options exactly",
    "Due Date": "YYYY-MM-DD",
    "Tags": ["array", "of", "strings — each must match schema options"],
    "Description": "string",
    "Requestor": "string"
  },
  "confidence": "high | medium | low",
  "notes": "string — brief reasoning about inferred values"
}
```

### Full example response

```json
{
  "task_name": "KdotWei is ready to collaborate with you on Notion Todos",
  "fields": {
    "Status": "Not Started",
    "Priority": "Medium",
    "Due Date": "2025-06-04",
    "Tags": ["notion", "collaboration", "updates"],
    "Description": "View KdotWei's Todos page. KdotWei's Workspace · 1 member · Write, plan, organise.",
    "Requestor": "KdotWei via Notion"
  },
  "confidence": "medium",
  "notes": "Priority set to Medium — no urgency signals in subject or snippet. Due Date inferred as received date + 7 days. Tags derived from email labels and subject keywords."
}
```
