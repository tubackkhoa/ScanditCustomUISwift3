/*
 * Copyright (C) 2015 - 2016, Daniel Dahan and CosmicMind, Inc. <http://cosmicmind.io>.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *	*	Redistributions of source code must retain the above copyright notice, this
 *		list of conditions and the following disclaimer.
 *
 *	*	Redistributions in binary form must reproduce the above copyright notice,
 *		this list of conditions and the following disclaimer in the documentation
 *		and/or other materials provided with the distribution.
 *
 *	*	Neither the name of CosmicMind nor the names of its
 *		contributors may be used to endorse or promote products derived from
 *		this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


import UIKit
import Material


class MCFlashCardNavigationController: BottomNavigationController, SBSScanDelegate, UIAlertViewDelegate {
  
  let kMainWidth = UIScreen.main.bounds.size.width
  let kMainHeight = UIScreen.main.bounds.size.height
  var soundOption = "sound"
  
  var picker : SBSBarcodePicker!
  var imgLine: UIImageView!
  
  var innerViewRect = CGRect.zero
  var overlayShape: CAShapeLayer!
  var opacity: Float = 0.5
  var timerScan: Timer!
  
  lazy var videoViewController: VideoViewController = {
    return UIStoryboard.viewController(identifier: "VideoViewController") as! VideoViewController
  }()
  
  lazy var audioViewController: AudioViewController = {
    return UIStoryboard.viewController(identifier: "AudioViewController") as! AudioViewController
  }()

  
  lazy var remindersViewController: RemindersViewController = {
    return UIStoryboard.viewController(identifier: "RemindersViewController") as! RemindersViewController
  }()
  
  lazy var searchViewController: SearchViewController = {
    return UIStoryboard.viewController(identifier: "SearchViewController") as! SearchViewController
  }()
  
  
  open override func prepare() {
    
    super.prepare()
    initPicker()
    initOverlay()
    prepareTabBar()
  }
  
  fileprivate func prepareTabBar() {
    
    viewControllers = [picker, VideoViewController(), AudioViewController(), RemindersViewController(), SearchViewController()];
    
    tabBar.depthPreset = .none
    tabBar.dividerColor = Color.grey.lighten3
  }
  
  
  private func hideSubviewsOf(_ view: UIView) {
    // Get the subviews of the view
    let subviews = view.subviews
    // Return if there are no subviews
    if subviews.count == 0 {
      return
    }
    // COUNT CHECK LINE
    for subview: UIView in subviews {
      subview.isHidden = true
      //            NSLog(@"%@", subview.class);
      // Do what you want to do with the subview
      // List the subviews of subview
      self.hideSubviewsOf(subview)
      
    }
  }
  
  
  func barcodePicker(_ picker: SBSBarcodePicker, didScan session: SBSScanSession) {
    // call stopScanning on the session to immediately stop scanning and close the camera. This
    // is the preferred way to stop scanning barcodes from the SBSScanDelegate as it is made
    // sure that no new codes are scanned. When calling stopScanning on the picker, another code
    // may be scanned before stopScanning has completely stoppen the scanning process.
    session.stopScanning();
    
    let code = session.newlyRecognizedCodes[0];
    // the barcodePicker:didScan delegate method is invoked from a picker-internal queue. To
    // display the results in the UI, you need to dispatch to the main queue. Note that it's not
    // allowed to use SBSScanSession in the dispatched block as it's only allowed to access the
    // SBSScanSession inside the barcodePicker(picker:didScan:) callback. It is however safe to
    // use results returned by session.newlyRecognizedCodes etc.
    DispatchQueue.main.async {
      let alert = UIAlertView();
      alert.delegate = self;
      alert.title = String(format:"Scanned code %@", code.symbologyString);
      alert.message = code.data;
      alert.addButton(withTitle:"OK");
      alert.show();
    }
  }
  
  
  func alertView(_ alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
    picker.startScanning();
  }
  
  
  
  func initPicker() {
    SBSLicense.setAppKey(kScanditBarcodeScannerAppKey);
    let settings = SBSScanSettings.default()
    settings.setSymbology(SBSSymbology.QR, enabled: true)
    picker = SBSBarcodePicker(settings: settings)
    picker.scanDelegate = self
    
    let isSound = soundOption.isEqual("sound")
    picker.overlayController.setBeepEnabled(isSound)
    picker.overlayController.setVibrateEnabled(!isSound)
    
    picker.tabBarItem.image = Icon.cm.photoCamera?.tintWithColor(color: Color.blueGrey.base)?.withRenderingMode(.alwaysOriginal)
    picker.tabBarItem.selectedImage = Icon.cm.photoCamera?.tintWithColor(color: Color.blue.base)?.withRenderingMode(.alwaysOriginal)
    
    
    self.hideSubviewsOf(picker.view)
    picker.overlayController.setViewfinderHeight(0.0, width: 0.0, landscapeHeight: 0.0, landscapeWidth: 0.0)

    
    picker.startScanning()
    
  }
  
  
  func drawCropView(_ rect: CGRect) {
    // padding from width of parent container with 50 inset
    var innerRect = rect.insetBy(dx: 50, dy: 50)
    let minSize: CGFloat = min(innerRect.size.width, innerRect.size.height)
    if innerRect.size.width != minSize {
      innerRect.origin.x += 50
      innerRect.size.width = minSize
    }
    else if innerRect.size.height != minSize {
      innerRect.origin.y += (rect.size.height - minSize) / 2 - rect.size.height / 6
      innerRect.size.height = minSize
    }
    
    let offsetRect = innerRect.offsetBy(dx: 0, dy: 15)
    innerViewRect = offsetRect
    overlayShape.path = UIBezierPath(rect: innerViewRect).cgPath
    
    self.addOtherLay(offsetRect)
  }
  
  func addOtherLay(_ rect: CGRect) {
    let layerTop = CAShapeLayer()
    layerTop.fillColor = UIColor.black.cgColor
    layerTop.opacity = opacity
    layerTop.path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: rect.origin.y)).cgPath
    picker.view.layer.addSublayer(layerTop)
    
    let layerLeft = CAShapeLayer()
    layerLeft.fillColor = UIColor.black.cgColor
    layerLeft.opacity = opacity
    layerLeft.path = UIBezierPath(rect: CGRect(x: 0, y: rect.origin.y, width: 50, height: UIScreen.main.bounds.size.height)).cgPath
    picker.view.layer.addSublayer(layerLeft)
    
    let layerRight = CAShapeLayer()
    layerRight.fillColor = UIColor.black.cgColor
    layerRight.opacity = opacity
    layerRight.path = UIBezierPath(rect: CGRect(x: UIScreen.main.bounds.size.width - 50, y: rect.origin.y, width: 50, height: UIScreen.main.bounds.size.height)).cgPath
    picker.view.layer.addSublayer(layerRight)
    
    let layerBottom = CAShapeLayer()
    layerBottom.fillColor = UIColor.black.cgColor
    layerBottom.opacity = opacity
    layerBottom.path = UIBezierPath(rect: CGRect(x: 50, y: rect.origin.y + rect.size.height, width: UIScreen.main.bounds.size.width - 100, height: UIScreen.main.bounds.size.height - rect.origin.y - rect.size.height)).cgPath
    picker.view.layer.addSublayer(layerBottom)
    
  }
  
  
  func initOverlay() {
    addOverlay()
    // add image line
    addImageLine()
    drawCropView(CGRect(x: 0, y: 0, width: kMainWidth, height: kMainHeight))
    imgLine.frame = CGRect(x: 0, y: innerViewRect.origin.y, width: kMainWidth, height: 12)
    if (timerScan != nil) {
      timerScan.invalidate()
      timerScan = nil
    }
    timerScan = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.scanAnimate), userInfo: nil, repeats: true)
    
    self.scanAnimate()
  }
  
  
  func addOverlay() {
    overlayShape = CAShapeLayer()
    overlayShape.backgroundColor = UIColor.red.cgColor
    overlayShape.fillColor = UIColor.clear.cgColor
    overlayShape.strokeColor = UIColor.lightGray.cgColor
    overlayShape.lineWidth = 1
    overlayShape.lineDashPattern = [50, 0]
    overlayShape.lineDashPhase = 1
    overlayShape.opacity = opacity
    picker.view.layer.addSublayer(overlayShape)
  }
  
  
  func scanAnimate() {
    // [self changeTorch];
    imgLine.frame = CGRect(x: 0, y: innerViewRect.origin.y, width: kMainWidth, height: 12)
    UIView.animate(withDuration: 2, animations: {() -> Void in
      self.imgLine.frame = CGRect(x: self.imgLine.frame.origin.x, y: self.imgLine.frame.origin.y + self.innerViewRect.size.height - 6, width: self.imgLine.frame.size.width, height: self.imgLine.frame.size.height)
      }, completion: { _ in })
  }
  
  
  func addImageLine() {
    let c_width: CGFloat = kMainWidth - 100
    let s_height: CGFloat = kMainHeight - 40
    let y: CGFloat = (s_height - c_width) / 2 - s_height / 6
    let corWidth: CGFloat = 16
    let img1 = UIImageView(frame: CGRect(x: 49, y: y + 76, width: corWidth, height: corWidth))
    img1.image = UIImage(named: "cor1")
    picker.view.addSubview(img1)
    let img2 = UIImageView(frame: CGRect(x: 35 + c_width, y: y + 76, width: corWidth, height: corWidth))
    img2.image = UIImage(named: "cor2")
    picker.view.addSubview(img2)
    let img3 = UIImageView(frame: CGRect(x: 49, y: y + c_width + 64, width: corWidth, height: corWidth))
    img3.image = UIImage(named: "cor3")
    picker.view.addSubview(img3)
    let img4 = UIImageView(frame: CGRect(x: 35 + c_width, y: y + c_width + 64, width: corWidth, height: corWidth))
    img4.image = UIImage(named: "cor4")
    picker.view.addSubview(img4)
    imgLine = UIImageView()
    imgLine.image = UIImage(named: "QRCodeScanLine")
    picker.view.addSubview(imgLine)
    
  }
  
}
