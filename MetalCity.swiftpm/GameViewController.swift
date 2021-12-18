//
//  GameViewController.swift
//  MetalSample
//
//  Created by Andy Qua on 28/06/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import UIKit
import MetalKit
import UserNotifications


class GameViewController: UIViewController {
    
    var menuButton : UIButton!
    var helpView : UITextView?
    
    var mtkView: MTKView!
    var device: MTLDevice!

    var renderer: Renderer!

    var menuHidden : Bool = true
    var menuExpanded : Bool = false

    override var prefersHomeIndicatorAutoHidden: Bool { return true }

    override func viewDidLoad() {
        super.viewDidLoad()

        UIApplication.shared.isIdleTimerDisabled = true
        self.view.isMultipleTouchEnabled = true
        
        view.backgroundColor = .black

        mtkView = MTKView()
        mtkView.layer.backgroundColor = UIColor.black.cgColor                
        mtkView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mtkView)
        
        menuButton = UIButton(type: .system)
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        menuButton.setTitle("Menu", for: .normal)
        menuButton.setTitleColor(.white, for: .normal)
        self.view.addSubview(menuButton)
        
        NSLayoutConstraint.activate([
            mtkView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            mtkView.topAnchor.constraint(equalTo: self.view.topAnchor),
            mtkView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            mtkView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),

            menuButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant:20),
            menuButton.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant:-20),
        ])

        setupMenu()
        
        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported")
            return
        }

        device = defaultDevice

        mtkView.device = device
        mtkView.backgroundColor = UIColor.black

        guard let newRenderer = Renderer(metalKitView: mtkView) else {
            print("Renderer cannot be initialized")
            return
        }

        self.view.layoutIfNeeded()
        renderer = newRenderer

        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)

        mtkView.delegate = renderer

        let gr = UIPanGestureRecognizer(target: self, action: #selector(pan))
        self.view.addGestureRecognizer(gr)

        let tapGr = UITapGestureRecognizer(target: self, action: #selector(tap))
        tapGr.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapGr)
        
        // Register for showMessage notifications
        NotificationCenter.default.addObserver(self, selector: #selector(onShowMessage(_:)), name: .showMessage, object: nil)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        renderer.setup()
    }

    @objc func onShowMessage( _ notif : Notification ) {
        guard let d = notif.userInfo,
              let msg = d["msg"] as? String else { return }
        
        print( msg )
        //showToast( message:msg )
    }

    var prevPoint = CGPoint()
    var nrTouches = 0
    
    @objc func tap(_ gr: UITapGestureRecognizer) {
        let p = gr.location(in:self.view)
        
        if let helpView = self.helpView {
            if !helpView.frame.contains(p) {
                helpView.removeFromSuperview()
            }
        }
    }
    
    @objc func pan(_ gr: UIPanGestureRecognizer) {
        let p = gr.location(in: self.view)
        switch gr.state {
        case .began:
            prevPoint = p
            nrTouches = gr.numberOfTouches
        case .changed:
            if gr.numberOfTouches != nrTouches {
                prevPoint = p
                nrTouches = gr.numberOfTouches
            }
            let dx = Float(p.x - prevPoint.x)
            let dy = Float(p.y - prevPoint.y)
            if nrTouches == 1 {
                if p.x > self.view.bounds.width - 100 {
                    raiseCamera(dy:dy)
                } else {
                    rotateViewUpAndDown(dy:dy)
                    rotateView(dx:dx)
                }
            } else if nrTouches == 2 {
                rotateView(dx:dx)
                moveCamera(dy:dy)
            } else if nrTouches == 3 {
                raiseCamera(dy:dy)
                strafeCamera(dx:dx)
            }
            prevPoint = p
        default:
            break
        }
    }

    func rotateView(dx: Float) {
        renderer.camera.rotateViewRound(x: 0, y: dx * 0.01, z: 0)
    }

    func rotateViewUpAndDown(dy: Float) {
        let deltaY = -dy * 0.01
        var v = renderer.camera.lookAt
        v.y += deltaY * 30
        renderer.camera.lookAt = v
    }

    func moveCamera(dy: Float) {
        renderer.camera.moveCamera(speed: -dy * 0.01)
    }

    func raiseCamera(dy: Float) {
        renderer.camera.raiseCamera(amount: dy*0.1)
    }

    func strafeCamera(dx: Float) {
        renderer.camera.strafeCamera(speed: -dx * 0.005)
    }
}


// MARK: Menu
extension GameViewController {
    func setupMenu() {
        
        // shortcut: (.command, "A")
        let toggleAutocam = UIAction(title: "Toggle autocam",
                                     image: UIImage(systemName: "video.fill")) { [unowned self] _ in
            self.renderer.toggleAutocam()
        }
                
        let rebuildCity = UIAction(title: "Rebuild city",
                                     image: UIImage(systemName: "building.2.fill")) { [unowned self] _ in
            self.renderer.rebuildCity()
        }
        
        let regenTextures = UIAction(title: "Regenerate textures",
                                     image: UIImage(systemName: "paintbrush.fill")) { [unowned self] _ in
            self.renderer.regenerateTextures()
        }

        let help = UIAction(title: "Help",
                                     image: UIImage(systemName: "questionmark")) {  _ in
            
            self.showHelp()
        }

        var autoCamModes = [UIAction]()
        for mode in CameraBehaviour.allCases {
            let action = UIAction(title: mode.string) {  _ in
                self.renderer.setAutoCam(mode:mode)
            }
            autoCamModes.append(action)
        }
        let autoCamMenu = UIMenu(title: "AutoCam Modes", children: autoCamModes)


        let menu = UIMenu(title: "", children: [toggleAutocam, autoCamMenu, rebuildCity, regenTextures, help])
        
        self.menuButton.showsMenuAsPrimaryAction = true
        self.menuButton.menu = menu
    }
    
    func showHelp() {
        if helpView == nil {
            let helpText = """
MetalCity by Andy Qua

Basic controls (autocam should be disable from the menu first!)

1 finger drag - look around
2 finger drag - move forward/backwards and look around
3 finger drag - stafe and move camera up and down
"""
            let x = self.view.frame.size.width - 550
            helpView = UITextView( frame:CGRect(x:x, y:100, width:500, height: 250))
            helpView?.backgroundColor = UIColor.black
            helpView?.layer.borderWidth = 2
            helpView?.font = UIFont.systemFont(ofSize: 20.0)
            helpView?.layer.borderColor = UIColor.systemMint.cgColor
            helpView?.layer.cornerRadius = 10
            helpView?.textColor = .white
            helpView?.text = helpText
            helpView?.isEditable = false
        }
        self.view.addSubview( helpView! )
    }
}
