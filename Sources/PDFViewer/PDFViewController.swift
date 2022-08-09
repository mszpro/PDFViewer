//
//  ViewController.swift
//  PDFViewer
//
//  Created by Sora on 2022/08/09.
//

#if os(iOS)

import UIKit
import PDFKit

@available(iOS 13.0, *)
func getPDFViewController(pdfFileLocalURL: URL,
                          excludedActivityTypes: [UIActivity.ActivityType] = []) -> PDFViewController? {
    let storyboard = UIStoryboard(name: "PDFViewer", bundle: Bundle.init(for: PDFViewController.self))
    guard let pdfVC = storyboard.instantiateViewController(withIdentifier: "PDFViewController") as? PDFViewController else {
        return nil
    }
    pdfVC.url = pdfFileLocalURL
    pdfVC.excludedActivityTypes = excludedActivityTypes
    return pdfVC
}

@available(iOS 13.0, *)
public class PDFViewController: UIViewController {
    
    @IBOutlet weak var pdfView: PDFView!
    @IBOutlet weak var pdfThumbnailView: PDFThumbnailView!
    @IBOutlet weak var bottomButton: UIButton!
    
    var pdfDocument: PDFDocument!
    public var url: URL?
    public var excludedActivityTypes: [UIActivity.ActivityType] = []

    public override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        bottomButton.isEnabled = false
        if #available(iOS 15, *) {
            bottomButton.configuration = .borderedTinted()
        }
        loadPDF()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    func loadPDF() {
        guard let url = url else {
            return
        }
        navigationItem.title = url.lastPathComponent
        pdfDocument = .init(url: url)
        pdfView.autoScales = true
        pdfView.enableDataDetectors = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .horizontal
        pdfView.displaysPageBreaks = true
        pdfView.pageBreakMargins = UIEdgeInsets(top: 10.0, left: 20.0, bottom: 10.0, right: 20.0)
        pdfView.usePageViewController(true)
        pdfView.document = pdfDocument
        pdfThumbnailView.layoutMode = .horizontal
        pdfThumbnailView.pdfView = pdfView
        pdfThumbnailView.thumbnailSize = .init(width: 80, height: 145)
        NotificationCenter.default.addObserver(self, selector: #selector(handlePageChange), name: Notification.Name.PDFViewPageChanged, object: nil)
        handlePageChange()
    }
    
    @objc func handlePageChange() {
        self.bottomButton.alpha = 1
        if let currentPage = self.pdfView.currentPage {
            let currentPageIndex = self.pdfDocument.index(for: currentPage)
            let totalPageCount = self.pdfDocument.pageCount
            self.bottomButton.setTitle("\(currentPageIndex + 1) / \(totalPageCount)", for: .normal)
            Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                UIView.animate(withDuration: 2.0, delay: 0, options: [.curveEaseIn], animations: {
                    self.bottomButton.alpha = 0
                }, completion: nil)
            }
        }
    }
    
    @IBAction func actionClose() {
        self.dismiss(animated: true)
    }
    
    @IBAction func actionShare() {
        guard let url = url else {
            return
        }
        let shareVC = UIActivityViewController(activityItems: [url], applicationActivities: [])
        shareVC.excludedActivityTypes = self.excludedActivityTypes
        self.present(shareVC, animated: true)
    }
    
    @IBAction func actionPrint() {
        guard let url = url,
              let pdfFileData = try? Data(contentsOf: url) else {
            return
        }
            
        let printController = UIPrintInteractionController.shared
        
        let printInfo = UIPrintInfo(dictionary:nil)
        printInfo.outputType = .general
        
        printController.printInfo = printInfo
        printController.printingItem = pdfFileData
        
        printController.present(animated: true, completionHandler: nil)
    }

}

#endif
