.PHONY: ci ci-check ts-check-diff ts-fix-diff html-check-diff html-fix-diff check-ts run-dev repomix check-ts-rules check-sushi-data setup
# =============================================================================
# Any Products Makefile
# =============================================================================

# CI: 全てのチェックを実行 (自動修正あり)
ci:
	python3 scripts/run_ci.py

# CI (サーバ) 向け: 自動修正せず、差分があれば失敗
ci-check:
	$(MAKE) ts-check-diff
	$(MAKE) html-check-diff
	$(MAKE) check-ts
	$(MAKE) check-ts-rules

# 開発サーバー起動
run-dev:
	pnpm run dev

# 各プロジェクトディレクトリで TypeScript の型チェックを実行
check-ts:
	@echo "Checking TypeScript in all projects..."
	@for dir in $$(find . -maxdepth 2 -name "tsconfig.json" -not -path "*/node_modules/*" -not -path "./_template/*" -exec dirname {} \;) ; do \
		if [ "$$dir" != "." ] && [ "$$dir" != "./_template" ]; then \
			echo "------------------------------------------------------------"; \
			echo "Checking: $$dir"; \
			pnpm exec tsc --noEmit -p $$dir/tsconfig.json || exit 1; \
		fi \
	done
	@echo "------------------------------------------------------------"
	@echo "TypeScript check completed successfully."

# カスタムルールのチェック
check-ts-rules:
	python3 scripts/check_ts_rules.py

# 寿司データのチェック
check-sushi-data:
	@echo "Checking sushi data..."
	@scripts=$$(ls check_scripts/*.mjs check_scripts/*.js check_scripts/*.py check_scripts/*.sh 2>/dev/null); \
	if [ -z "$$scripts" ]; then \
		echo "No check scripts found in check_scripts/"; \
	else \
		for script in $$scripts; do \
			echo "Running $$script..."; \
			case "$$script" in \
				*.py) python3 $$script || exit 1 ;; \
				*.sh) sh $$script || exit 1 ;; \
				*) node $$script || exit 1 ;; \
			esac; \
		done; \
	fi

# TS/TSXの静的解析（Biome使用）
ts-check-diff:
	@files="$$( ( \
		if [ "$$CI" = "true" ]; then \
			git ls-files '*.ts' '*.tsx' | grep -v '^_template/'; \
		else \
			git diff --name-only --diff-filter=ACMRTUXB HEAD -- '*.ts' '*.tsx' 2>/dev/null; \
			git diff --cached --name-only --diff-filter=ACMRTUXB HEAD -- '*.ts' '*.tsx' 2>/dev/null; \
			git ls-files --others --exclude-standard -- '*.ts' '*.tsx' 2>/dev/null; \
		fi \
	) | sort -u )"; \
	if [ -z "$$files" ]; then \
		echo "No TS/TSX files to check."; \
		exit 0; \
	fi; \
	echo "Checking TS/TSX files:"; \
	echo "$$files" | sed 's/^/ - /'; \
	pnpm exec biome check $$files

# TS/TSXの自動修正
ts-fix-diff:
	@files="$$( ( \
		if [ "$$CI" = "true" ]; then \
			git ls-files '*.ts' '*.tsx' | grep -v '^_template/'; \
		else \
			git diff --name-only --diff-filter=ACMRTUXB HEAD -- '*.ts' '*.tsx' 2>/dev/null; \
			git diff --cached --name-only --diff-filter=ACMRTUXB HEAD -- '*.ts' '*.tsx' 2>/dev/null; \
			git ls-files --others --exclude-standard -- '*.ts' '*.tsx' 2>/dev/null; \
		fi \
	) | sort -u )"; \
	if [ -z "$$files" ]; then \
		echo "No TS/TSX files to fix."; \
		exit 0; \
	fi; \
	echo "Fixing TS/TSX files:"; \
	echo "$$files" | sed 's/^/ - /'; \
	pnpm exec biome check --write $$files

# HTMLのチェック（Prettier使用）
html-check-diff:
	@files="$$( ( \
		if [ "$$CI" = "true" ]; then \
			git ls-files '*.html' | grep -v '^_template/'; \
		else \
			git diff --name-only --diff-filter=ACMRTUXB HEAD -- '*.html' 2>/dev/null; \
			git diff --cached --name-only --diff-filter=ACMRTUXB HEAD -- '*.html' 2>/dev/null; \
			git ls-files --others --exclude-standard -- '*.html' 2>/dev/null; \
		fi \
	) | sort -u )"; \
	if [ -z "$$files" ]; then \
		echo "No HTML files to check."; \
		exit 0; \
	fi; \
	echo "Checking HTML files:"; \
	echo "$$files" | sed 's/^/ - /'; \
	pnpm exec prettier --check $$files

# HTMLの自動修正
html-fix-diff:
	@files="$$( ( \
		if [ "$$CI" = "true" ]; then \
			git ls-files '*.html' | grep -v '^_template/'; \
		else \
			git diff --name-only --diff-filter=ACMRTUXB HEAD -- '*.html' 2>/dev/null; \
			git diff --cached --name-only --diff-filter=ACMRTUXB HEAD -- '*.html' 2>/dev/null; \
			git ls-files --others --exclude-standard -- '*.html' 2>/dev/null; \
		fi \
	) | sort -u )"; \
	if [ -z "$$files" ]; then \
		echo "No HTML files to fix."; \
		exit 0; \
	fi; \
	echo "Fixing HTML files:"; \
	echo "$$files" | sed 's/^/ - /'; \
	pnpm exec prettier --write $$files

# プロジェクト全体を一つのファイルにまとめる (LLM用)
repomix:
	@mkdir -p tmp/repomix
	# フルバージョン
	pnpm dlx repomix --output tmp/repomix/repomix-full.txt
	# ロックファイル、画像、ライセンス等を除外したバージョン
	pnpm dlx repomix --ignore "**/pnpm-lock.yaml,**/node_modules/**,**/*.png,**/*.jpg,**/*.jpeg,**/*.gif,**/*.svg,**/*.ico,LICENSE,**/.agent/**" --output tmp/repomix/repomix-lite.txt
	# さらにテストファイルを除外したバージョン
	pnpm dlx repomix --ignore "**/pnpm-lock.yaml,**/node_modules/**,**/*.png,**/*.jpg,**/*.jpeg,**/*.gif,**/*.svg,**/*.ico,LICENSE,**/.agent/**,**/*.test.ts,**/test/**,public/robots.txt,public/sitemap.xml,public/site.webmanifest,.gitignore,scripts/*.py,Makefile,vitest.config.ts,README.md" --output tmp/repomix/repomix-lite-no-tests.txt

setup:
	curl -fsSL https://raw.githubusercontent.com/HappyOnigiri/ShareSettings/main/SyncRule/run.sh | bash
	corepack enable
	pnpm install --frozen-lockfile
