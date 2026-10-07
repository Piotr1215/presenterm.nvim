---@class PresenterMTemplatesModule
local M = {}

---@class PresenterMTemplate
---@field name string Display name
---@field description string Template description
---@field category string Category (tech-talk, workshop, etc.)
---@field content fun(vars: table): string Function that generates content

---Default presentation templates
M.default_templates = {
  ['tech-talk'] = {
    name = 'Tech Talk',
    description = 'Technical presentation with demo sections',
    category = 'presentation',
    content = function(vars)
      return string.format(
        [[---
title: %s
author: %s
---

<!-- column_layout: [1, 1] -->
<!-- column: 0 -->
# %s

<!-- column: 1 -->
**%s**

%s

<!-- reset_layout -->
<!-- end_slide -->

# Agenda

- Introduction
- Problem Statement
- Solution Overview
- Technical Deep Dive
- Demo
- Q&A

<!-- end_slide -->

# Introduction

<!-- pause -->

## Who Am I?

%s

<!-- end_slide -->

# Problem Statement

<!-- pause -->

## The Challenge

- Describe the problem
- Why it matters
- Current limitations

<!-- end_slide -->

# Solution Overview

<!-- pause -->

## Our Approach

- Key innovation
- Benefits
- Trade-offs

<!-- end_slide -->

# Technical Deep Dive

<!-- pause -->

## Architecture

```
[Add your architecture diagram or code here]
```

<!-- end_slide -->

# Demo

<!-- pause -->

```bash +exec
# Live demo code here
echo "Hello from the demo!"
```

<!-- end_slide -->

# Key Takeaways

<!-- pause -->

- Takeaway 1
- Takeaway 2
- Takeaway 3

<!-- end_slide -->

# Q&A

<!-- pause -->

<!-- column_layout: [1, 1] -->
<!-- column: 0 -->

## Questions?

<!-- column: 1 -->

**Contact:**
%s

<!-- reset_layout -->
<!-- end_slide -->

# Thank You!

<!-- pause -->

Find the slides at: %s

<!-- end_slide -->
]],
        vars.title,
        vars.author,
        vars.title,
        vars.author,
        vars.date or os.date('%Y-%m-%d'),
        vars.author,
        vars.contact or vars.author,
        vars.repo or '[Your repo URL]'
      )
    end,
  },

  ['lightning-talk'] = {
    name = 'Lightning Talk (5 min)',
    description = 'Quick 5-minute presentation format',
    category = 'presentation',
    content = function(vars)
      return string.format(
        [[---
title: %s
author: %s
---

# %s

**%s**

%s

<!-- end_slide -->

# The Problem

<!-- pause -->

One sentence problem statement

<!-- end_slide -->

# The Solution

<!-- pause -->

One sentence solution

<!-- end_slide -->

# How It Works

<!-- pause -->

```
[Simple code or diagram]
```

<!-- end_slide -->

# Results

<!-- pause -->

- Key metric 1
- Key metric 2
- Key metric 3

<!-- end_slide -->

# Try It Yourself

%s

**Thank you!**

<!-- end_slide -->
]],
        vars.title,
        vars.author,
        vars.title,
        vars.author,
        vars.date or os.date('%Y-%m-%d'),
        vars.repo or '[Your repo URL]'
      )
    end,
  },

  ['workshop'] = {
    name = 'Workshop/Tutorial',
    description = 'Hands-on workshop with exercises',
    category = 'education',
    content = function(vars)
      return string.format(
        [[---
title: %s
author: %s
---

# %s

**A Hands-On Workshop**

%s

Instructor: %s

<!-- end_slide -->

# Workshop Goals

<!-- pause -->

By the end of this workshop, you will:

- Learn core concepts
- Build a working example
- Understand best practices

<!-- end_slide -->

# Prerequisites

<!-- pause -->

Please ensure you have:

- Tool/Software 1
- Tool/Software 2
- Basic knowledge of X

<!-- end_slide -->

# Setup

<!-- pause -->

```bash +exec
# Clone the repository
git clone %s
cd project
```

<!-- end_slide -->

# Module 1: Foundations

<!-- pause -->

## Key Concepts

- Concept 1
- Concept 2
- Concept 3

<!-- end_slide -->

# Exercise 1

<!-- pause -->

**Your Task:**

1. Step 1
2. Step 2
3. Step 3

⏱️ **Time: 5 minutes**

<!-- end_slide -->

# Solution 1

<!-- pause -->

```
[Solution code here]
```

<!-- end_slide -->

# Module 2: Advanced Topics

<!-- pause -->

## Going Deeper

- Advanced topic 1
- Advanced topic 2

<!-- end_slide -->

# Exercise 2

<!-- pause -->

**Your Task:**

Apply what you learned to build...

⏱️ **Time: 10 minutes**

<!-- end_slide -->

# Wrap Up

<!-- pause -->

## Key Takeaways

- Summary 1
- Summary 2
- Summary 3

<!-- end_slide -->

# Resources

- Documentation: [URL]
- Examples: %s
- Community: [URL]

**Questions?**

<!-- end_slide -->
]],
        vars.title,
        vars.author,
        vars.title,
        vars.date or os.date('%Y-%m-%d'),
        vars.author,
        vars.repo or '[Repository URL]',
        vars.repo or '[Repository URL]'
      )
    end,
  },

  ['minimal'] = {
    name = 'Minimal',
    description = 'Blank presentation with basic structure',
    category = 'basic',
    content = function(vars)
      return string.format(
        [[---
title: %s
author: %s
---

# %s

%s

%s

<!-- end_slide -->

# Slide 2

Your content here

<!-- end_slide -->

# Slide 3

Your content here

<!-- end_slide -->
]],
        vars.title,
        vars.author,
        vars.title,
        vars.author,
        vars.date or os.date('%Y-%m-%d')
      )
    end,
  },

  ['pitch'] = {
    name = 'Pitch/Sales',
    description = 'Product pitch or sales presentation',
    category = 'business',
    content = function(vars)
      return string.format(
        [[---
title: %s
author: %s
---

<!-- column_layout: [1, 1] -->
<!-- column: 0 -->

# %s

<!-- column: 1 -->

**%s**

%s

<!-- reset_layout -->
<!-- end_slide -->

# The Problem

<!-- pause -->

## Pain Points

- Customer pain point 1
- Customer pain point 2
- Customer pain point 3

<!-- end_slide -->

# The Solution

<!-- pause -->

<!-- column_layout: [1, 1] -->
<!-- column: 0 -->

## %s

Your solution description

<!-- column: 1 -->

**Key Benefits:**
- Benefit 1
- Benefit 2
- Benefit 3

<!-- reset_layout -->
<!-- end_slide -->

# How It Works

<!-- pause -->

```
[Demo or architecture]
```

<!-- end_slide -->

# Why Us?

<!-- pause -->

## Competitive Advantages

- Advantage 1
- Advantage 2
- Advantage 3

<!-- end_slide -->

# Traction

<!-- pause -->

- Metric 1: [Number]
- Metric 2: [Number]
- Metric 3: [Number]

<!-- end_slide -->

# Pricing

<!-- pause -->

<!-- column_layout: [1, 1, 1] -->
<!-- column: 0 -->

**Starter**

$XX/month

<!-- column: 1 -->

**Pro**

$XXX/month

<!-- column: 2 -->

**Enterprise**

Custom

<!-- reset_layout -->
<!-- end_slide -->

# Next Steps

<!-- pause -->

## Let's Get Started

- Schedule a demo
- Start free trial
- Contact us: %s

<!-- end_slide -->
]],
        vars.title,
        vars.author,
        vars.title,
        vars.author,
        vars.date or os.date('%Y-%m-%d'),
        vars.product or 'Our Product',
        vars.contact or vars.author
      )
    end,
  },
}

---Get list of available templates
---@return table List of template keys and metadata
function M.list()
  local templates = {}
  for key, tmpl in pairs(M.default_templates) do
    table.insert(templates, {
      key = key,
      name = tmpl.name,
      description = tmpl.description,
      category = tmpl.category,
    })
  end
  table.sort(templates, function(a, b)
    return a.name < b.name
  end)
  return templates
end

---Get template by key
---@param key string Template key
---@return PresenterMTemplate|nil
function M.get(key)
  return M.default_templates[key]
end

---Generate presentation from template
---@param template_key string Template key
---@param vars table Variables for template (title, author, etc.)
---@return string Generated presentation content
function M.generate(template_key, vars)
  local template = M.get(template_key)
  if not template then
    error('Template not found: ' .. template_key)
  end
  return template.content(vars)
end

---Sample variables for preview generation
M.sample_vars = {
  title = 'Sample Presentation',
  author = 'Your Name',
  date = os.date('%Y-%m-%d'),
  contact = 'your@email.com',
  repo = 'https://github.com/user/repo',
  product = 'Product Name',
}

---Generate preview content for a template (truncated to 100 lines)
---@param template_key string Template key
---@return string[] lines Preview lines
function M.generate_preview(template_key)
  local content = M.generate(template_key, M.sample_vars)
  local lines = vim.split(content, '\n')

  if #lines > 100 then
    lines = vim.list_slice(lines, 1, 100)
    table.insert(lines, '')
    table.insert(lines, '... (truncated)')
  end

  return lines
end

return M
