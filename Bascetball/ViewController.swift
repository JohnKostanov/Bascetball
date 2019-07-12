//
//  ViewController.swift
//  Bascetball
//
//  Created by  Джон Костанов on 10/07/2019.
//  Copyright © 2019 John Kostanov. All rights reserved.
//

import ARKit

class ViewController: UIViewController {
    
    // MARK: Outlets
    @IBOutlet var sceneView: ARSCNView!
    
    // MARK: - Properties
    var isHoopPlaced = false {
        didSet {
            if isHoopPlaced {
                guard let configuration = sceneView.session.configuration as? ARWorldTrackingConfiguration else { return }
                configuration.planeDetection = []
                sceneView.session.run(configuration)
            }
        }
    }
    
    // MARK: - UIViewController Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    // MARK: - Custom Methods
    func addBall() {
        guard let frame = sceneView.session.currentFrame else { return }
        let ball = SCNNode(geometry: SCNSphere(radius: 0.25))
        ball.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(
            node: ball,
            options: [SCNPhysicsShape.Option.collisionMargin: 0.01]))
        ball.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/ball.jpg")
        let transform = SCNMatrix4(frame.camera.transform)
        ball.transform = transform
        let power = Float(10)
        let force = SCNVector3(-transform.m31 * power, -transform.m32 * power, -transform.m33 * power)
        ball.physicsBody?.applyForce(force, asImpulse: true)
        sceneView.scene.rootNode.addChildNode(ball)
    }
    
    func addHoop(result: ARHitTestResult) {
        let hoop = SCNScene(named: "art.scnassets/hoop.scn")!.rootNode.clone()
        hoop.simdTransform = result.worldTransform
        hoop.eulerAngles.x -= .pi / 2
        sceneView.scene.rootNode.addChildNode(hoop)
        let chape = SCNPhysicsShape(
            node: hoop,
            options: [ SCNPhysicsShape.Option.type:SCNPhysicsShape.ShapeType.concavePolyhedron ])
        let body = SCNPhysicsBody(type: .static, shape: chape)
        hoop.physicsBody = body
        
        sceneView.scene.rootNode.enumerateChildNodes { node, _ in
            if node.name == "Wall" {
                node.removeFromParentNode()
            }
        }
    }
    
    func createWall(planeAnchor: ARPlaneAnchor) -> SCNNode {
        let extent = planeAnchor.extent
        let width = CGFloat(extent.x)
        let height = CGFloat(extent.y)
        let plane = SCNPlane(width: width, height: height)
        plane.firstMaterial?.diffuse.contents = UIColor.red
        let wall = SCNNode(geometry: plane)
        
        wall.eulerAngles.x = -.pi / 2
        wall.name = "Wall"
        wall.opacity = 0.125
        
        return wall
    }
    
    // MARK: - Action
    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
        if isHoopPlaced {
            addBall()
        } else {
            let touchLocation = sender.location(in: sceneView)
            let hitTestResult = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
            if let nearestResult = hitTestResult.first {
                addHoop(result: nearestResult)
                isHoopPlaced = true
            }
        }
        
    }
    

}

// MARK: - ARSCNViewDelegate
extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let wall = createWall(planeAnchor: planeAnchor)
        node.addChildNode(wall)
    }
}
