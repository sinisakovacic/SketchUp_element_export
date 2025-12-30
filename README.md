# element_export
element_export is lightweight SketchUp extension for exporting selected Groups and Components dimensions, thickness and edge‑banding into a clean CSV file for creating accurate woodworking cut‑lists.

## 📌 Overview
It exports selected Groups and Component Instances into a clean CSV file suitable for:
+ Cut‑list optimizers
+ CNC preparation workflows
+ Excel/Sheets processing
+ Carpentry production planning

The exporter automatically detects:
+ Part name (from Tag/Layer)
+ Length, width, thickness
+ Edge banding on all four sides
+ Materials applied to faces (not just components)
+ This makes it ideal for cabinetmaking, furniture design, and any workflow where SketchUp models are converted into real‑world production data.

## ✨ Features
### Automatic Dimension Detection
The script reads the bounding box of each selected object and determines:
1. Thickness → smallest dimension
2. Width → middle dimension
3. Length → largest dimension
This ensures consistent orientation regardless of how the part is drawn.

### Smart Material Detection (3‑Level Scan)
Materials are detected from:
1. Component instance
2. Component definition
3. Individual faces inside the component
This is essential because many users apply edge‑banding materials directly to faces.

### Multi‑Side Edge Banding Detection
If different faces have different materials, the script detects all of them.
Banding rules (exact material name match):

| **Material Name**  | **Banding Side** |
| ------------------ | ---------------- |
|     Color A01   	 |    Left (eb_l)   |
|     Color A02	     |    Right (eb_r)  |
|     Color A03	     |    Right (eb_t)  |
|     Color A04	     |    Right (eb_b)  |

Multiple sides can be banded on the same part.

### Tag‑Based Naming
Part names are taken from the Tag (Layer) assigned to the object.
Fallbacks:
1. Component instance name
2. Component definition name
3. "Unnamed"

### Clean CSV Output
The exported CSV contains:
```
name,length,width,thickness,eb_l,eb_r,eb_t,eb_b
```

## 📁 Example Output
```
name,length,width,thickness,eb_l,eb_r,eb_t,eb_b
Front,720,396,18,1,1,0,0
Side,720,560,18,0,0,0,0
Shelf,720,560,16,1,0,1,1
```

## 🛠 Installation
1. Copy the .rb file into your SketchUp Plugins folder:
+ Windows:  
C:\Users\<username>\AppData\Roaming\SketchUp\SketchUp 20xx\SketchUp\Plugins

+ macOS:  
~/Library/Application Support/SketchUp 20xx/SketchUp/Plugins
3. Restart SketchUp.
4. The extension will appear under:
Extensions → element export

## 🚀 Usage
1. Select one or more Groups or Components in SketchUp.
2. Go to Extensions → element export.
3. Choose a location to save dimenzije.csv.
4. Import the CSV into your cut‑list optimizer or CNC workflow.

## 🤝 Contributing
Pull requests and feature suggestions are welcome.
