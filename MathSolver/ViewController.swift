//
//  ViewController.swift
//  MathSolver
//
//  Created by Thai Nguyen on 1/26/20.
//  Copyright © 2020 Thai Nguyen. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

enum MathOperations: CaseIterable {
    case add, multiply
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var question: UILabel!
    
    @IBOutlet weak var correct: UIImageView!
    
    
    var answer: Int? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
       askQuestion()
    }
    
    
    func createUniqueQuestion() -> (text: String, answer: Int) {
        let operation = MathOperations.allCases.randomElement()!
        var question = ""
        var answer = 0
        
        
        repeat {
            switch operation {
            case .add:
                let firstNumber = Int.random(in: 1...50)
                let secondNumber = Int.random(in: 1...49)
                question = "What is \(firstNumber) plus \(secondNumber)?"
                
                answer = firstNumber + secondNumber
            case .multiply:
                let firstNumber = Int.random(in: 1...10)
                let secondNumber = Int.random(in: 1...9)
                question = "What is \(firstNumber) times \(secondNumber)?"
                
                answer = firstNumber * secondNumber
            }
        } while !answer.hasUniqueDigits
        
        return (question, answer)
    }
    
    
    func askQuestion() {
        let newQuestion = createUniqueQuestion()
        question.text = newQuestion.text
        answer = newQuestion.answer
        
        question.alpha = 0
        
        UIView.animate(withDuration: 0.5) {
            self.question.alpha = 1
            
            self.correct.alpha = 0
            self.correct.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        }
    }
    
    
    func correctAnswer() {
        correct.transform = CGAffineTransform(scaleX: 2, y: 2)
        
        UIView.animate(withDuration: 0.5) {
            self.correct.transform = .identity
            self.correct.alpha = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.askQuestion()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()
        
        guard let trackingImages = ARReferenceImage.referenceImages(inGroupNamed: "Numbers", bundle: nil) else {
            fatalError("Couldn't load tracking image")
        }
        
        configuration.trackingImages = trackingImages
        
        configuration.maximumNumberOfTrackedImages = 2

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    

    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        guard let imageAnchor = anchor as? ARImageAnchor else { return nil }
        
        let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
        
        plane.firstMaterial?.diffuse.contents = UIColor.blue.withAlphaComponent(0.5)
        
        let planeNode = SCNNode(geometry: plane)
        
        planeNode.eulerAngles.x = -.pi / 2
        
        let node = SCNNode()
     
        node.addChildNode(planeNode)
        
        return node
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let anchors = sceneView.session.currentFrame?.anchors else { return }
        
        // Filter that array down so we only have tracked image anchors
        let visiblesAnchors = anchors.filter {
            guard let anchor = $0 as? ARImageAnchor else { return false }
            
            return anchor.isTracked
        }
        
        let nodes = visiblesAnchors.sorted { anchor1, anchor2 -> Bool in
            guard let node1 = sceneView.node(for: anchor1) else { return false }
            
            guard let node2 = sceneView.node(for: anchor2) else { return false }
            
            return node1.worldPosition.x < node2.worldPosition.x
        }
        
        // boil our node names down to single string
        let combined = nodes.reduce("") { $0 + ($1.name ?? "") }
        
        let userAnswer = Int(combined) ?? 0
        
        if userAnswer == answer {
            // if they got it right, clear answer so we don't get multiple submissions of the same answer
            answer = nil
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.correctAnswer()
            }
        }
    }

    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}


extension Int {
    var hasUniqueDigits: Bool {
        let str = String(self)
        let uniqueLetters = Set(str)
        
        return str.count == uniqueLetters.count
    }
}
