.PHONY: build test clean install uninstall format lint docs

# Build the project
build:
	dune build

# Run tests
test:
	dune runtest

# Clean build artifacts
clean:
	dune clean

# Install the package
install:
	dune install

# Uninstall the package
uninstall:
	dune uninstall

# Format code
format:
	dune build @fmt --auto-promote

# Check code formatting
lint:
	dune build @fmt

# Generate documentation
docs:
	dune build @doc

# Run examples
examples:
	dune build examples/basic_example.exe
	dune build examples/error_example.exe

# Install dependencies
deps:
	opam install . --deps-only --with-test --with-dev

# Create a new release
release:
	dune-release tag
	dune-release distrib
	dune-release publish

# Development setup
dev-setup: deps
	opam install ocamlformat merlin
	dune build

# Quick development cycle
dev: build test
