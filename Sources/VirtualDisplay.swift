import Foundation
import CoreGraphics
import ObjectiveC

private func allocInstance(of cls: NSObject.Type) -> NSObject {
    typealias AllocFn = @convention(c) (AnyObject, Selector) -> AnyObject
    let sel = NSSelectorFromString("alloc")
    let method = class_getClassMethod(cls, sel)!
    let imp = method_getImplementation(method)
    let fn = unsafeBitCast(imp, to: AllocFn.self)
    return fn(cls, sel) as! NSObject
}

final class VirtualDisplay {
    private var display: NSObject?
    private let queue = DispatchQueue(label: "club.nosleep.virtual-display")

    var displayID: CGDirectDisplayID? {
        guard let display else { return nil }
        let sel = NSSelectorFromString("displayID")
        guard display.responds(to: sel) else { return nil }
        typealias GetID = @convention(c) (AnyObject, Selector) -> UInt32
        let method = class_getInstanceMethod(type(of: display), sel)!
        let fn = unsafeBitCast(method_getImplementation(method), to: GetID.self)
        return fn(display, sel)
    }

    func create(width: Int = 1920, height: Int = 1080, hiDPI: Bool = false) -> Bool {
        guard let descClass = NSClassFromString("CGVirtualDisplayDescriptor") as? NSObject.Type,
              let displayClass = NSClassFromString("CGVirtualDisplay") as? NSObject.Type,
              let settingsClass = NSClassFromString("CGVirtualDisplaySettings") as? NSObject.Type,
              let modeClass = NSClassFromString("CGVirtualDisplayMode") as? NSObject.Type
        else {
            printError("CGVirtualDisplay API not available on this system")
            return false
        }

        let desc = descClass.init()
        desc.perform(NSSelectorFromString("setName:"), with: "nosleepclub Virtual Display")
        desc.perform(NSSelectorFromString("setDispatchQueue:"), with: queue)
        invokeSetUInt32(on: desc, selector: "setMaxPixelsWide:", value: UInt32(width))
        invokeSetUInt32(on: desc, selector: "setMaxPixelsHigh:", value: UInt32(height))
        invokeSetCGSize(on: desc, selector: "setSizeInMillimeters:", value: CGSize(width: 530, height: 300))
        invokeSetUInt32(on: desc, selector: "setVendorID:", value: 0x1337)
        invokeSetUInt32(on: desc, selector: "setProductID:", value: 0x0001)
        invokeSetUInt32(on: desc, selector: "setSerialNum:", value: 0x0001)

        let initSel = NSSelectorFromString("initWithDescriptor:")
        guard displayClass.instancesRespond(to: initSel) else {
            printError("CGVirtualDisplay initWithDescriptor: not available")
            return false
        }

        let allocated = allocInstance(of: displayClass)
        guard let vdResult = allocated.perform(initSel, with: desc),
              let vd = vdResult.takeUnretainedValue() as? NSObject else {
            printError("Failed to create virtual display")
            return false
        }

        let mode = createMode(modeClass: modeClass, width: width, height: height, refreshRate: 60.0)
        if let mode {
            let settings = settingsClass.init()
            settings.perform(NSSelectorFromString("setModes:"), with: NSArray(object: mode))
            invokeSetBool(on: settings, selector: "setHiDPI:", value: hiDPI)
            vd.perform(NSSelectorFromString("applySettings:"), with: settings)
        }

        display = vd
        return true
    }

    func destroy() {
        display = nil
    }

    private func createMode(modeClass: NSObject.Type, width: Int, height: Int, refreshRate: Double) -> NSObject? {
        let sel = NSSelectorFromString("initWithWidth:height:refreshRate:")
        guard modeClass.instancesRespond(to: sel) else { return nil }

        typealias InitFn = @convention(c) (AnyObject, Selector, Int, Int, Double) -> AnyObject?
        let obj = allocInstance(of: modeClass)
        let method = class_getInstanceMethod(type(of: obj), sel)!
        let fn = unsafeBitCast(method_getImplementation(method), to: InitFn.self)
        return fn(obj, sel, width, height, refreshRate) as? NSObject
    }

    private func invokeSetUInt32(on obj: NSObject, selector: String, value: UInt32) {
        let sel = NSSelectorFromString(selector)
        guard obj.responds(to: sel) else { return }
        typealias Fn = @convention(c) (AnyObject, Selector, UInt32) -> Void
        let method = class_getInstanceMethod(type(of: obj), sel)!
        unsafeBitCast(method_getImplementation(method), to: Fn.self)(obj, sel, value)
    }

    private func invokeSetCGSize(on obj: NSObject, selector: String, value: CGSize) {
        let sel = NSSelectorFromString(selector)
        guard obj.responds(to: sel) else { return }
        typealias Fn = @convention(c) (AnyObject, Selector, CGSize) -> Void
        let method = class_getInstanceMethod(type(of: obj), sel)!
        unsafeBitCast(method_getImplementation(method), to: Fn.self)(obj, sel, value)
    }

    private func invokeSetBool(on obj: NSObject, selector: String, value: Bool) {
        let sel = NSSelectorFromString(selector)
        guard obj.responds(to: sel) else { return }
        typealias Fn = @convention(c) (AnyObject, Selector, Bool) -> Void
        let method = class_getInstanceMethod(type(of: obj), sel)!
        unsafeBitCast(method_getImplementation(method), to: Fn.self)(obj, sel, value)
    }
}
