//
//  ViewController.swift
//  ARBasketBall
//
//  Created by Emin Roblack on 10/5/18.
//  Copyright © 2018 emiN Roblack. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
  
  @IBOutlet weak var planeDetected: UILabel!
  @IBOutlet weak var sceneView: ARSCNView!
  
  let configuration = ARWorldTrackingConfiguration()
  var courtAdded: Bool {
    return sceneView.scene.rootNode.childNode(withName: "court", recursively: false) != nil
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
    sceneView.autoenablesDefaultLighting = true
    configuration.planeDetection = .horizontal
    self.sceneView.session.run(configuration)
    
    sceneView.delegate = self
    
    let tapGestureReckognizer = UITapGestureRecognizer(target: self, action: #selector(addCourt(sender:)))
    sceneView.addGestureRecognizer(tapGestureReckognizer)
}
  
  func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    guard anchor is ARPlaneAnchor else {return}
    
    DispatchQueue.main.async {
      self.planeDetected.isHidden = false
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now()+3) {
      self.planeDetected.isHidden = true
    }

  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if courtAdded == true {
      
      removeBalls()
      
      guard let pointOfView = sceneView.pointOfView else {return}
      
      let transform = pointOfView.transform
      let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
      let location = SCNVector3(transform.m41, transform.m42, transform.m43)
      let currentCameraPosition = orientation + location
      
      let ballNode = SCNNode(geometry: SCNSphere(radius: 0.3))
      ballNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "pumpkinTexture")
      
      let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ballNode))
      body.restitution = 0.2
      ballNode.physicsBody = body
      
      ballNode.position = currentCameraPosition
      ballNode.name = "theBall"
      
      ballNode.physicsBody?.applyForce(SCNVector3(orientation.x*10, orientation.y*10, orientation.z*10), asImpulse: true)
      
      self.sceneView.scene.rootNode.addChildNode(ballNode)
      
      
    }
  }
  
  func removeBalls() {
    sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
      if node.name == "theBall" {
        node.removeFromParentNode()
      }
    }
  }
  
  @objc func addCourt(sender: UITapGestureRecognizer) {
    guard let view = sender.view as? ARSCNView else {return}
    let tapLocation = sender.location(in: view)
    let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
    
    if !hitTestResults.isEmpty {
      place(atLocation: hitTestResults.first!)
    } else {
      ///
    }
    
  }
  
  func place(atLocation: ARHitTestResult) {
    
    let basketScene = SCNScene(named: "art.scnassets/court.scn")
    guard let basketNode = basketScene?.rootNode.childNode(withName: "court", recursively: false) else {return}
    
    let transform = atLocation.worldTransform
    
    basketNode.position = SCNVector3(transform.columns.3.x,
                                      transform.columns.3.y,
                                      transform.columns.3.z)
    basketNode.physicsBody = SCNPhysicsBody(type: .static,
                                            shape: SCNPhysicsShape(node: basketNode, options: [SCNPhysicsShape.Option.keepAsCompound: true, SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
    
  sceneView.scene.rootNode.addChildNode(basketNode)
    
  }
  
  
  

}

func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
  return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

