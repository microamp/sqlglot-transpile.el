;;; sqlglot-transpile.el --- Emacs wrapper for SQLGlot SQL transpilation -*- lexical-binding: t; -*-

;; Copyright (C) 2025

;; Author: Sangho Na
;; Version: 0.0.1
;; Package-Requires: ((emacs "25.1"))
;; Keywords: sql, databases, transpile, format
;; URL: https://github.com/microamp/sqlglot-transpile.el

;;; Commentary:

;; This package provides an Emacs wrapper around SQLGlot's transpile function
;; for SQL dialect translation and pretty-printing.
;;
;; SQLGlot is a Python SQL parser and transpiler that can translate SQL
;; between 30+ different dialects including BigQuery, Snowflake, Spark,
;; PostgreSQL, MySQL, and more.
;;
;; Usage:
;;   M-x sqlglot-transpile-region - Transpile selected SQL
;;   M-x sqlglot-transpile-buffer - Transpile entire buffer
;;   M-x sqlglot-format-region    - Format/pretty-print selected SQL
;;   M-x sqlglot-format-buffer    - Format/pretty-print entire buffer

;;; Code:

(require 'json)

(defgroup sqlglot nil
  "SQLGlot SQL transpilation interface."
  :group 'sql
  :prefix "sqlglot-")

(defcustom sqlglot-python-executable "python3"
  "Python executable to use for running SQLGlot."
  :type 'string
  :group 'sqlglot)

(defcustom sqlglot-script-path nil
  "Path to the sqlglot_transpile.py script.
If nil, assumes script is in the same directory as this file."
  :type '(choice (const :tag "Auto-detect" nil)
                 (file :tag "Custom path"))
  :group 'sqlglot)

(defcustom sqlglot-default-read-dialect "mysql"
  "Default read SQL dialect for transpilation."
  :type 'string
  :group 'sqlglot)

(defcustom sqlglot-default-write-dialect "postgresql"
  "Default write SQL dialect for transpilation."
  :type 'string
  :group 'sqlglot)

;; TODO: Read dynamically
(defconst sqlglot-supported-dialects
  '("athena" "bigquery" "clickhouse" "databricks" "doris" "dremio"
    "drill" "druid" "duckdb" "dune" "fabric" "hive" "materialize"
    "mysql" "oracle" "postgres" "postgresql" "presto" "prql"
    "redshift" "risingwave" "snowflake" "spark" "spark2" "sqlite"
    "starrocks" "tableau" "teradata" "trino" "tsql" "exasol")
  "List of SQL dialects supported by SQLGlot.")

(defun sqlglot--get-script-path ()
  "Get the path to the sqlglot_transpile.py script."
  (or sqlglot-script-path
      (expand-file-name "sqlglot_transpile.py"
                        (file-name-directory (or load-file-name buffer-file-name)))))

(defun sqlglot--run-script-command (args)
  "Execute the SQLGlot script with ARGS and return the result."
  (let ((script-path (sqlglot--get-script-path)))
    (unless (file-exists-p script-path)
      (error "SQLGlot script not found at: %s" script-path))
    (with-temp-buffer
      (let ((exit-code (apply #'call-process sqlglot-python-executable nil t nil script-path args)))
        (if (= exit-code 0)
            (buffer-string)
          (error "SQLGlot execution failed: %s" (buffer-string)))))))

(defun sqlglot--run-script-with-stdin (args sql)
  "Execute the SQLGlot script with ARGS, passing SQL via stdin."
  (let ((script-path (sqlglot--get-script-path)))
    (unless (file-exists-p script-path)
      (error "SQLGlot script not found at: %s" script-path))
    (with-temp-buffer
      (insert sql)
      (let ((exit-code (apply #'call-process-region (point-min) (point-max)
                              sqlglot-python-executable t t nil script-path args)))
        (if (= exit-code 0)
            (buffer-string)
          (error "SQLGlot execution failed: %s" (buffer-string)))))))

(defun sqlglot--transpile-sql (sql read-dialect write-dialect)
  "Transpile SQL from READ-DIALECT to WRITE-DIALECT using SQLGlot."
  (let ((args (append (list "transpile")
                      (when read-dialect (list "--read" read-dialect))
                      (when write-dialect (list "--write" write-dialect)))))
    (sqlglot--run-script-with-stdin args sql)))

(defun sqlglot--format-sql (sql &optional read-dialect write-dialect)
  "Format/pretty-print SQL using SQLGlot with optional READ-DIALECT and WRITE-DIALECT."
  (let ((args (cond
               ((and read-dialect write-dialect)
                (list "format" "--read" read-dialect "--write" write-dialect))
               (read-dialect
                (list "format" "--read" read-dialect))
               (write-dialect
                (list "format" "--write" write-dialect))
               (t
                (list "format")))))
    (sqlglot--run-script-with-stdin args sql)))

(defun sqlglot--read-dialect (prompt default)
  "Read a SQL dialect from user with PROMPT and DEFAULT value."
  (completing-read prompt sqlglot-supported-dialects nil nil nil nil default))

;;;###autoload
(defun sqlglot-transpile-region (start end &optional read-dialect write-dialect)
  "Transpile SQL in region from READ-DIALECT to WRITE-DIALECT.
START and END define the region boundaries."
  (interactive
   (let ((dialects (when current-prefix-arg
                     (list (let ((read-dialect (sqlglot--read-dialect "Read dialect (optional): " "")))
                             (if (string-empty-p read-dialect) nil read-dialect))
                           (let ((write-dialect (sqlglot--read-dialect "Write dialect (optional): " "")))
                             (if (string-empty-p write-dialect) nil write-dialect))))))
     (list (region-beginning)
           (region-end)
           (nth 0 dialects)
           (nth 1 dialects))))
  (let* ((sql (buffer-substring-no-properties start end))
         (transpiled (sqlglot--transpile-sql sql read-dialect write-dialect)))
    (delete-region start end)
    (insert transpiled)
    (message "Transpiled%s"
             (cond
              ((and read-dialect write-dialect)
               (format " from %s to %s" read-dialect write-dialect))
              (read-dialect
               (format " from %s" read-dialect))
              (write-dialect
               (format " to %s" write-dialect))
              (t "")))))

;;;###autoload
(defun sqlglot-transpile-buffer (&optional read-dialect write-dialect)
  "Transpile entire buffer from READ-DIALECT to WRITE-DIALECT."
  (interactive
   (when current-prefix-arg
     (list (let ((read-dialect (sqlglot--read-dialect "Read dialect (optional): " "")))
             (if (string-empty-p read-dialect) nil read-dialect))
           (let ((write-dialect (sqlglot--read-dialect "Write dialect (optional): " "")))
             (if (string-empty-p write-dialect) nil write-dialect)))))
  (sqlglot-transpile-region (point-min) (point-max) read-dialect write-dialect))

;;;###autoload
(defun sqlglot-format-region (start end &optional read-dialect write-dialect)
  "Format/pretty-print SQL in region with optional READ-DIALECT and WRITE-DIALECT.
START and END define the region boundaries."
  (interactive
   (let ((dialects (when current-prefix-arg
                     (list (let ((read-dialect (sqlglot--read-dialect "Read dialect (optional): " "")))
                             (if (string-empty-p read-dialect) nil read-dialect))
                           (let ((write-dialect (sqlglot--read-dialect "Write dialect (optional): " "")))
                             (if (string-empty-p write-dialect) nil write-dialect))))))
     (list (region-beginning)
           (region-end)
           (nth 0 dialects)
           (nth 1 dialects))))
  (let* ((sql (buffer-substring-no-properties start end))
         (formatted (sqlglot--format-sql sql read-dialect write-dialect)))
    (delete-region start end)
    (insert formatted)
    (message "Formatted SQL%s"
             (cond
              ((and read-dialect write-dialect)
               (format " (%s → %s)" read-dialect write-dialect))
              (read-dialect
               (format " as %s" read-dialect))
              (write-dialect
               (format " as %s" write-dialect))
              (t "")))))

;;;###autoload
(defun sqlglot-format-buffer (&optional read-dialect write-dialect)
  "Format/pretty-print entire buffer with optional READ-DIALECT and WRITE-DIALECT."
  (interactive
   (when current-prefix-arg
     (list (let ((read-dialect (sqlglot--read-dialect "Read dialect (optional): " "")))
             (if (string-empty-p read-dialect) nil read-dialect))
           (let ((write-dialect (sqlglot--read-dialect "Write dialect (optional): " "")))
             (if (string-empty-p write-dialect) nil write-dialect)))))
  (sqlglot-format-region (point-min) (point-max) read-dialect write-dialect))

;;;###autoload
(defun sqlglot-check-installation ()
  "Check if SQLGlot is properly installed and accessible."
  (interactive)
  (condition-case err
      (let ((version-output (sqlglot--run-script-command '("version"))))
        (message "SQLGlot version: %s" (string-trim version-output)))
    (error
     (message "SQLGlot is not installed or not accessible. Install with: pip install sqlglot"))))

;;;###autoload
(defun sqlglot-list-dialects ()
  "List all supported SQL dialects."
  (interactive)
  (condition-case err
      (let* ((dialects-json (sqlglot--run-script-command '("dialects")))
             (dialects-list (json-read-from-string dialects-json)))
        (with-output-to-temp-buffer "*SQLGlot Dialects*"
          (princ "Supported SQL Dialects:\n\n")
          (dolist (dialect dialects-list)
            (princ (format "  %s\n" dialect)))))
    (error
     (message "Failed to retrieve dialect list: %s" (error-message-string err)))))

(provide 'sqlglot-transpile)
;;; sqlglot-transpile.el ends here
