### An Experiment in Mixing UIKit and SwiftUI layout

This little example project shows the beginnings of a class, `OverlayViewController`. It is designed to be added as a child view controller and presents itself like a drawer at the bottom of the screen. It is generic and takes a SwiftUI `View` which it hosts and presents within itself.

The constraints for `OverlayViewController` define a padding around the `UIHostingController.view`.  The height of the `OverlayViewController.view` should be established by the height of the hosted **SwiftUI** `ExampleView`. When the overlay is initially presented, there is mysterious extra top and bottom padding around the `ExampleView`.  If the app is forced to layout again by rotating it to landscape and back, the views will be positioned correctly.

### Question

Is there a way to force the UIKit and SwiftUI layout systems to position the views correctly when initially presenting them?

<div align="center">
<table>
<tr>
<td>
<img src="https://github.com/briancordanyoung/OverlayPlay/blob/master/InitialLayout.png" width="282">
</td>
<td>
<img src="https://github.com/briancordanyoung/OverlayPlay/blob/master/CorrectLayout.png" width="282">
</td>
</tr>
<tr>
<td >
<div style="text-align:center">Initial Layout</div>
</td>
<td>
<div style="text-align:center">Correct Layout</div>
</td>
</tr>
</table>
</div>