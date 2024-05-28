import Cocoa
import SpriteKit

class ViewController: NSViewController {
    @IBOutlet weak var skView: SKView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)

        skView.showsFPS = true
        skView.showsNodeCount = true
    }
}
