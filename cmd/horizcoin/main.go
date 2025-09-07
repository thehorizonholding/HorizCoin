package main

import (
	"fmt"
	"os"

	"github.com/thehorizonholding/HorizCoin/internal/version"
)

func main() {
	args := os.Args[1:]
	if len(args) == 0 {
		printHelp()
		return
	}

	switch args[0] {
	case "version":
		fmt.Println(version.String())
	case "demo":
		runDemo()
	default:
		fmt.Printf("unknown command: %s\n\n", args[0])
		printHelp()
	}
}

func printHelp() {
	fmt.Printf("HorizCoin %s\n", version.String())
	fmt.Println("Usage: horizcoin <command>")
	fmt.Println("\nCommands:")
	fmt.Println("  demo       run a short demonstration simulation")
	fmt.Println("  version    print version info")
}

func runDemo() {
	fmt.Println("Starting HorizCoin demo simulation...")
	for i := 1; i <= 3; i++ {
		fmt.Printf("  mining block %d... ok\n", i)
	}
	fmt.Println("Simulation complete. (Telemetry capture hooks TBD)")
}
