//
//  GameViewController.swift
//  ResearchSphere
//
//  Created by 川上 基樹 on 2016/09/06.
//  Copyright © 2016年 mothule. All rights reserved.
//

import GLKit
import OpenGLES

func BUFFER_OFFSET(i: Int) -> UnsafePointer<Void> {
    let p: UnsafePointer<Void> = nil
    return p.advancedBy(i)
}

class GameViewController: GLKViewController {
    var rotationYaw: Float = 0.0
    var rotationPitch: Float = 0.0
    var rotationVelocityYaw: Float = 0.0
    var rotationVelocityPitch: Float = 0.0

    var touchPrevPoint: CGPoint = CGPoint.zero

    var vertexArray: GLuint = 0
    var vertexBuffer: GLuint = 0

    var context: EAGLContext? = nil
    var effect: GLKBaseEffect? = nil


    deinit {
        self.tearDownGL()

        if EAGLContext.currentContext() === self.context {
            EAGLContext.setCurrentContext(nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.context = EAGLContext(API: .OpenGLES2)

        if !(self.context != nil) {
            print("Failed to create ES context")
        }

        let view = self.view as! GLKView
        view.context = self.context!
        view.drawableDepthFormat = .Format24
        

        self.setupGL()

        self.view.layer.magnificationFilter = kCAFilterNearest
        self.view.layer.minificationFilter = kCAFilterNearest
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        if self.isViewLoaded() && (self.view.window != nil) {
            self.view = nil

            self.tearDownGL()

            if EAGLContext.currentContext() === self.context {
                EAGLContext.setCurrentContext(nil)
            }
            self.context = nil
        }
    }

    var textureInfo: GLKTextureInfo?
    func setupGL() {
        EAGLContext.setCurrentContext(self.context)

        self.effect = GLKBaseEffect()
        self.effect!.useConstantColor = GLboolean(GL_TRUE)

//        glEnable(GLenum(GL_DEPTH_TEST))
//        glEnable(GLenum(GL_DITHER))

        glGenVertexArraysOES(1, &vertexArray)
        glBindVertexArrayOES(vertexArray)

        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), GLsizeiptr(sizeof(GLfloat) * gSphereVertexData.count), &gSphereVertexData, GLenum(GL_STATIC_DRAW))

        do {
            let filePath = NSBundle.mainBundle().pathForResource("sample3", ofType: "JPG")
            textureInfo = try GLKTextureLoader.textureWithContentsOfFile(filePath!, options: nil)
//            textureInfo = try GLKTextureLoader.textureWithCGImage((UIImage(named:"sample3_inv")?.CGImage)!, options: nil)
        } catch {
            print(error)
        }

        // 頂点情報の設定
        // XYZ座標
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.Position.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.Position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), Int32(sizeof(GLfloat) * 5), BUFFER_OFFSET(0))
        // 2Dテクスチャ
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.TexCoord0.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.TexCoord0.rawValue), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), Int32(sizeof(GLfloat)*5), BUFFER_OFFSET(12))

        glBindVertexArrayOES(0)
    }

    func tearDownGL() {
        EAGLContext.setCurrentContext(self.context)

        glDeleteBuffers(1, &vertexBuffer)
        glDeleteVertexArraysOES(1, &vertexArray)

        self.effect = nil
    }

    // MARK: - GLKView and GLKViewController delegate methods

    func update() {
        let aspect = fabsf(Float(self.view.bounds.size.width / self.view.bounds.size.height))
        let projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(50.0), aspect, 0.01, 50.0)

        self.effect?.transform.projectionMatrix = projectionMatrix

        self.effect?.texture2d0.enabled = GLboolean(GL_TRUE)
        self.effect?.texture2d0.name = textureInfo!.name
        
        var baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, 0.0)
        baseModelViewMatrix = GLKMatrix4RotateWithVector3(baseModelViewMatrix, rotationYaw, GLKVector3Make(0,1,0))
        baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, rotationPitch, cosf(rotationYaw), 0.0, sinf(rotationYaw) )
        
        // Compute the model view matrix for the object rendered with GLKit
//        var modelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, -5.0)
        var modelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, 0.0)
//        modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, 1.0, 1.0, 1.0)
//        modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, rotation, 0.0, 1.0, 0.0)
        modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix)
        self.effect?.transform.modelviewMatrix = modelViewMatrix


        rotationYaw += Float(self.timeSinceLastUpdate * Double(0.15))
        rotationYaw += Float(self.timeSinceLastUpdate * Double(rotationVelocityYaw))
        rotationPitch += Float(self.timeSinceLastUpdate * Double(rotationVelocityPitch))
        
        rotationVelocityYaw *= 0.9
        rotationVelocityPitch *= 0.9
        if fabsf(rotationVelocityYaw) <= 0.0000001 {
            rotationVelocityYaw = 0.0
        }
        if fabsf(rotationVelocityPitch) <= 0.0000001 {
            rotationVelocityPitch = 0.0
        }
    }

    override func glkView(view: GLKView, drawInRect rect: CGRect) {
        glClearColor(1.0, 1.0, 1.0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT) | GLbitfield(GL_DEPTH_BUFFER_BIT))

        glBindVertexArrayOES(vertexArray)

        // Render the object with GLKit
        self.effect?.prepareToDraw()

//        glDrawArrays(GLenum(GL_LINES), 0, GLsizei(gSphereVertexData.count/5))
        glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(gSphereVertexData.count/5))
    }


    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        rotationVelocityYaw = 0.0
        rotationVelocityPitch = 0.0

        let touch: UITouch = touches.first! as UITouch
        let pos: CGPoint = touch.locationInView(self.view)
        touchPrevPoint = pos
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch: UITouch = touches.first! as UITouch
        let pos: CGPoint = touch.locationInView(self.view)
        
        
        let distanceX = sqrtf( Pow(Float(pos.x - touchPrevPoint.x) ))
        let distanceY = sqrtf( Pow(Float(pos.y - touchPrevPoint.y) ))
        
        
        let radianX = atanf((distanceX/2.0)/50.0) * 2.0
        rotationVelocityYaw += radianX * (touchPrevPoint.x - pos.x < 0.0 ? -1.0 : 1.0)

        let radianY = atanf((distanceY/2.0)/50.0) * 2.0
        rotationVelocityPitch += radianY * (touchPrevPoint.y - pos.y < 0.0 ? -1.0 : 1.0)
        
        touchPrevPoint = pos
    }

    private func Pow(val: Float) -> Float {
        return val * val
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {

    }

    class func getSphere() -> [GLfloat] {

        let pi = GLfloat(M_PI)
        let pi2 = 2.0 * pi
        let stackSize = 32
        let vtxSize = 32
        let maxRadius: GLfloat = 1.0

        var vtxes: [GLfloat] = []

        for stackIdx in 0..<stackSize {
            let r1      =  sinf(pi * (GLfloat(stackIdx    ) / GLfloat(stackSize)))
            let h1      = -cosf(pi * (GLfloat(stackIdx    ) / GLfloat(stackSize)))
            let r2      =  sinf(pi * (GLfloat(stackIdx + 1) / GLfloat(stackSize)))
            let h2      = -cosf(pi * (GLfloat(stackIdx + 1) / GLfloat(stackSize)))
            let tv1     =  sinf(pi/2.0 * (GLfloat(stackIdx  ) / GLfloat(stackSize)))
            let tv2     =  sinf(pi/2.0 * (GLfloat(stackIdx+1) / GLfloat(stackSize)))
            print("現階層:\(stackIdx) 現階層の高さ:\(h1) 現階層の中心からの距離:\(r1) 次階層の高さ:\(h2) 次階層の中心からの距離:\(r2)")

            let radius1 = maxRadius * r1
            let radius2 = maxRadius * r2

            for vtxIdx in 0..<vtxSize {
                let theta1 = pi2 * (GLfloat(vtxIdx    ) / GLfloat(vtxSize))
                let theta2 = pi2 * (GLfloat(vtxIdx + 1) / GLfloat(vtxSize))
                let tu1 = sinf(pi/2.0 * (GLfloat(vtxIdx) / GLfloat(vtxSize)))
                let tu2 = sinf(pi/2.0 * (GLfloat(vtxIdx+1) / GLfloat(vtxSize)))

                let x11: GLfloat = radius1 * cosf(theta1)
                let y11: GLfloat = radius1 * sinf(theta1)
                let u11: GLfloat = tu1
                let v11: GLfloat = tv1

                let x12: GLfloat = radius1 * cosf(theta2)
                let y12: GLfloat = radius1 * sinf(theta2)
                let u12: GLfloat = tu2
                let v12: GLfloat = tv1

                let x21: GLfloat = radius2 * cosf(theta1)
                let y21: GLfloat = radius2 * sinf(theta1)
                let u21: GLfloat = tu1
                let v21: GLfloat = tv2

                let x22: GLfloat = radius2 * cosf(theta2)
                let y22: GLfloat = radius2 * sinf(theta2)
                let u22: GLfloat = tu2
                let v22: GLfloat = tv2


                vtxes += [ x11, h1, y11, u11, v11]
                vtxes += [ x21, h2, y21, u21, v21]
                vtxes += [ x22, h2, y22, u22, v22]
                print("v1(\(x11),\(h1),\(y11)) v2(\(x21),\(h2),\(y21)) v3(\(x22),\(h2),\(y22))")

                vtxes += [ x11, h1, y11, u11, v11]
                vtxes += [ x22, h2, y22, u22, v22]
                vtxes += [ x12, h1, y12, u12, v12]
                print("v4(\(x11),\(h1),\(y11)) v5(\(x22),\(h2),\(y22)) v6(\(x12),\(h1),\(y12))")
            }
        }
        return vtxes


//        return [
//            -1.0, -1.0, -1.0, 0, 0, 1,
//            -1.0,  1.0, -1.0, 0, 0, 1,
//             1.0,  1.0, -1.0, 0, 0, 1,
//
//             1.0,  1.0, -1.0, 0, 0, 1,
//             1.0, -1.0, -1.0, 0, 0, 1,
//            -1.0, -1.0, -1.0, 0, 0, 1,
//        ]
    }
}

var gSphereVertexData: [GLfloat] = GameViewController.getSphere()

var gCubeVertexDataInv: [GLfloat] = [
    // Data layout for each line below is:
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,
    0.5, -0.5, -0.5, -1.0, 0.0, 0.0,
    0.5, 0.5, -0.5, -1.0, 0.0, 0.0,
    0.5, -0.5, 0.5, -1.0, 0.0, 0.0,
    0.5, -0.5, 0.5, -1.0, 0.0, 0.0,
    0.5, 0.5, -0.5, -1.0, 0.0, 0.0,
    0.5, 0.5, 0.5, -1.0, 0.0, 0.0,

    0.5, 0.5, -0.5, 0.0, -1.0, 0.0,
    -0.5, 0.5, -0.5, 0.0, -1.0, 0.0,
    0.5, 0.5, 0.5, 0.0, -1.0, 0.0,
    0.5, 0.5, 0.5, 0.0, -1.0, 0.0,
    -0.5, 0.5, -0.5, 0.0, -1.0, 0.0,
    -0.5, 0.5, 0.5, 0.0, -1.0, 0.0,

    -0.5, 0.5, -0.5, 1.0, 0.0, 0.0,
    -0.5, -0.5, -0.5, 1.0, 0.0, 0.0,
    -0.5, 0.5, 0.5, 1.0, 0.0, 0.0,
    -0.5, 0.5, 0.5, 1.0, 0.0, 0.0,
    -0.5, -0.5, -0.5, 1.0, 0.0, 0.0,
    -0.5, -0.5, 0.5, 1.0, 0.0, 0.0,

    -0.5, -0.5, -0.5, 0.0, 1.0, 0.0,
    0.5, -0.5, -0.5, 0.0, 1.0, 0.0,
    -0.5, -0.5, 0.5, 0.0, 1.0, 0.0,
    -0.5, -0.5, 0.5, 0.0, 1.0, 0.0,
    0.5, -0.5, -0.5, 0.0, 1.0, 0.0,
    0.5, -0.5, 0.5, 0.0, 1.0, 0.0,

    0.5, 0.5, 0.5, 0.0, 0.0, -1.0,
    -0.5, 0.5, 0.5, 0.0, 0.0, -1.0,
    0.5, -0.5, 0.5, 0.0, 0.0, -1.0,
    0.5, -0.5, 0.5, 0.0, 0.0, -1.0,
    -0.5, 0.5, 0.5, 0.0, 0.0, -1.0,
    -0.5, -0.5, 0.5, 0.0, 0.0, -1.0,

    0.5, -0.5, -0.5, 0.0, 0.0, 1.0,
    -0.5, -0.5, -0.5, 0.0, 0.0, 1.0,
    0.5, 0.5, -0.5, 0.0, 0.0, 1.0,
    0.5, 0.5, -0.5, 0.0, 0.0, 1.0,
    -0.5, -0.5, -0.5, 0.0, 0.0, 1.0,
    -0.5, 0.5, -0.5, 0.0, 0.0, 1.0
]


var gCubeVertexData: [GLfloat] = [
    // Data layout for each line below is:
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,
     0.5, -0.5, -0.5, 1.0, 0.0, 0.0,
     0.5, 0.5, -0.5, 1.0, 0.0, 0.0,
     0.5, -0.5, 0.5, 1.0, 0.0, 0.0,
     0.5, -0.5, 0.5, 1.0, 0.0, 0.0,
     0.5, 0.5, -0.5, 1.0, 0.0, 0.0,
     0.5, 0.5, 0.5, 1.0, 0.0, 0.0,

     0.5, 0.5, -0.5, 0.0, 1.0, 0.0,
    -0.5, 0.5, -0.5, 0.0, 1.0, 0.0,
     0.5, 0.5, 0.5, 0.0, 1.0, 0.0,
     0.5, 0.5, 0.5, 0.0, 1.0, 0.0,
    -0.5, 0.5, -0.5, 0.0, 1.0, 0.0,
    -0.5, 0.5, 0.5, 0.0, 1.0, 0.0,

    -0.5, 0.5, -0.5, -1.0, 0.0, 0.0,
    -0.5, -0.5, -0.5, -1.0, 0.0, 0.0,
    -0.5, 0.5, 0.5, -1.0, 0.0, 0.0,
    -0.5, 0.5, 0.5, -1.0, 0.0, 0.0,
    -0.5, -0.5, -0.5, -1.0, 0.0, 0.0,
    -0.5, -0.5, 0.5, -1.0, 0.0, 0.0,

    -0.5, -0.5, -0.5, 0.0, -1.0, 0.0,
     0.5, -0.5, -0.5, 0.0, -1.0, 0.0,
    -0.5, -0.5, 0.5, 0.0, -1.0, 0.0,
    -0.5, -0.5, 0.5, 0.0, -1.0, 0.0,
     0.5, -0.5, -0.5, 0.0, -1.0, 0.0,
     0.5, -0.5, 0.5, 0.0, -1.0, 0.0,

     0.5, 0.5, 0.5, 0.0, 0.0, 1.0,
    -0.5, 0.5, 0.5, 0.0, 0.0, 1.0,
     0.5, -0.5, 0.5, 0.0, 0.0, 1.0,
     0.5, -0.5, 0.5, 0.0, 0.0, 1.0,
    -0.5, 0.5, 0.5, 0.0, 0.0, 1.0,
    -0.5, -0.5, 0.5, 0.0, 0.0, 1.0,

     0.5, -0.5, -0.5, 0.0, 0.0, -1.0,
    -0.5, -0.5, -0.5, 0.0, 0.0, -1.0,
     0.5, 0.5, -0.5, 0.0, 0.0, -1.0,
     0.5, 0.5, -0.5, 0.0, 0.0, -1.0,
    -0.5, -0.5, -0.5, 0.0, 0.0, -1.0,
    -0.5, 0.5, -0.5, 0.0, 0.0, -1.0
]
