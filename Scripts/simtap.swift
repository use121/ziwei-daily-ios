// 极简鼠标事件工具：给模拟器做 GUI 自动化用。
// 用法：simtap <x> <y> [按住秒数]
import CoreGraphics
import Foundation

let args = CommandLine.arguments
guard args.count >= 3, let x = Double(args[1]), let y = Double(args[2]) else {
    print("usage: simtap <x> <y> [holdSeconds]")
    exit(2)
}
let hold = args.count >= 4 ? Double(args[3]) ?? 0.05 : 0.05
let point = CGPoint(x: x, y: y)
let source = CGEventSource(stateID: .hidSystemState)

CGEvent(mouseEventSource: source, mouseType: .mouseMoved,
        mouseCursorPosition: point, mouseButton: .left)?.post(tap: .cghidEventTap)
usleep(120_000)
CGEvent(mouseEventSource: source, mouseType: .leftMouseDown,
        mouseCursorPosition: point, mouseButton: .left)?.post(tap: .cghidEventTap)
usleep(UInt32(hold * 1_000_000))
CGEvent(mouseEventSource: source, mouseType: .leftMouseUp,
        mouseCursorPosition: point, mouseButton: .left)?.post(tap: .cghidEventTap)
