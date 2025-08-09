# Table of Contents

- [sqlglot-transpile.el](#sqlglot-transpile.el)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Usage](#usage)
  - [TODOs](#todos)
  - [License](#license)

# sqlglot-transpile.el

[SQLGlot](https://sqlglot.com/sqlglot.html) (sqlglot.com) is a Python SQL parser and transpiler that can translate SQL between 30+ different dialects including BigQuery, Snowflake, Spark, PostgreSQL, MySQL, and more.

This elisp package provides a thin wrapper around SQLGlot's transpile function for SQL dialect translation and formatting/pretty-printing.

## Prerequisites

- SQLGlot

  ``` bash
  python -m pip install sqlglot
  ```

## Installation

- Emacs 30.1+:

  ``` elisp
  (use-package sqlglot-transpile
    :ensure t
    :vc (:url "https://github.com/microamp/sqlglot-transpile.el" :rev :newest))
  ```

## Usage

``` elisp
;; M-x sqlglot-transpile-region - Transpile selected SQL
;; M-x sqlglot-transpile-buffer - Transpile entire buffer
;; M-x sqlglot-format-region    - Format/pretty-print selected SQL
;; M-x sqlglot-format-buffer    - Format/pretty-print entire buffer
```

## TODOs

- [ ] Fetch supported dialects dynamically from SQLGlot

- [ ] Use Transient for configuring read and write dialects

## License

MIT
