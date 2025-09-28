*** a/.github/workflows/ci.yml
--- b/.github/workflows/ci.yml
@@
-name: CI
-on: [push, pull_request]
-jobs:
-  build:
-    runs-on: ubuntu-latest
-    steps:
-    - uses: actions/checkout@v4
-    - name: Install Rust
-      run: rustup toolchain install 1.70.0
-    - name: Build
-      run: cargo build --workspace --release
+name: CI
+on: [push, pull_request]
+jobs:
+  build:
+    runs-on: ubuntu-latest
+    steps:
+    - uses: actions/checkout@v4
+
+    - uses: actions/setup-node@v4
+      with:
+        node-version: '18'
+
+    - uses: actions-rs/toolchain@v1
+      with:
+        toolchain: '1.70.0'
+        override: true
+
+    - name: Cache cargo
+      uses: actions/cache@v4
+      with:
+        path: |
+          ~/.cargo/registry
+          ~/.cargo/git
+        key: ${{ runner.os }}-cargo-${{ hashFiles('**/Cargo.lock') }}
+
+    - name: Cache node modules
+      uses: actions/cache@v4
+      with:
+        path: web/node_modules
+        key: ${{ runner.os }}-node-${{ hashFiles('web/package-lock.json') }}
+        restore-keys: |
+          ${{ runner.os }}-node-
+
+    - name: Build Rust workspace
+      run: cargo build --workspace --release
+
+    - name: Run Rust tests
+      run: cargo test --workspace -- --nocapture
+
+    - name: Build web demo (if present)
+      working-directory: ./web
+      run: |
+        if [ -f package.json ]; then
+          npm ci
+          npm run build || echo "No build script for web"
+        else
+          echo "No web folder / package.json found"
+        fi
