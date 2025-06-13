SHELL_TARGET = shell.native
IDE_TARGET = ide.native

OCAMLBUILD_CMD = ocamlbuild -use-ocamlfind -pkg why3 -pkg lablgtk2

.PHONY: ide_server shell_server clean

ide_server:
	@echo "Building $(IDE_TARGET)..."
	$(OCAMLBUILD_CMD) $(IDE_TARGET)
	@echo "Build complete. Executable: _build/$(TARGET)"

shell_server:
	@echo "Building $(SHELL_TARGET)..."
	$(OCAMLBUILD_CMD) $(SHELL_TARGET)
	@echo "Build complete. Executable: _build/$(TARGET)"

clean:
	@echo "Cleaning build artifacts..."
	$(OCAMLBUILD_CMD) -clean
	@echo "Clean complete."

.PHONY: run
run: all
	@echo "Running $(TARGET)..."
	./_build/$(TARGET)
