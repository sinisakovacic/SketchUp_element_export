# ============================================================
#   element_export — SketchUp CSV Exporter
#   Exports: name, length, width, thickness, edge banding (L/R/T/B)
#   Author: Sinisa (sinisak@live.com)
#
#   This script scans selected Groups/Components and generates
#   a clean CSV cut-list for woodworking workflows.
#
#   Key features:
#   - Auto-detects dimensions (L/W/T)
#   - Detects materials from instance, definition, and faces
#   - Supports multi-side edge banding (A01/A02/A03/A04)
#   - Extracts thickness from material name (e.g., "18mm White")
#   - Uses Tag/Layer name as part name
# ============================================================

require 'sketchup.rb'

module SinisaTools
  module ExportObject

    MENU_NAME = "element_export"

    # CSV header row
    CSV_HEADERS = "name,length,width,thickness,eb_l,eb_r,eb_t,eb_b\n"

    # ------------------------------------------------------------
    # Detect ALL materials used on the object:
    # 1. Component instance material
    # 2. Component definition material
    # 3. Materials applied to individual faces
    #
    # Returns an array of lowercase material names.
    # ------------------------------------------------------------
    def self.detect_all_materials(entity)
      materials = []

      # Instance-level material
      materials << entity.material if entity.material

      # Definition-level material
      if entity.respond_to?(:definition) && entity.definition.material
        materials << entity.definition.material
      end

      # Face-level materials (most important for edge banding)
      if entity.respond_to?(:definition)
        entity.definition.entities.grep(Sketchup::Face).each do |face|
          materials << face.material if face.material
        end
      end

      # Normalize names: lowercase, unique
      materials.compact.map { |m| m.display_name.downcase }.uniq
    end

    # ------------------------------------------------------------
    # Main export function
    # ------------------------------------------------------------
    def self.export_csv
      model = Sketchup.active_model
      selection = model.selection

      # Require at least one selected object
      if selection.empty?
        UI.messagebox("Please select at least one Group or Component.")
        return
      end

      # Ask user where to save the CSV
      filepath = UI.savepanel("Save element", "", "dimenzije.csv")
      return unless filepath

      # Open CSV file for writing
      File.open(filepath, "w") do |file|
        file.write(CSV_HEADERS)

        # Process each selected entity
        selection.each do |entity|
          next unless entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)

          # --------------------------------------------------------
          # DIMENSION DETECTION
          # --------------------------------------------------------
          bbox = entity.bounds

          # Convert bounding box dimensions to mm
          # Replace *.round with *.round(2) for two decimal points
          x = bbox.width.to_mm.round
          y = bbox.height.to_mm.round
          z = bbox.depth.to_mm.round

          # Sort dimensions to determine L/W/T
          dims = [x, y, z].sort
          thickness = dims[0]   # smallest dimension
          width     = dims[1]   # middle dimension
          length    = dims[2]   # largest dimension

          # --------------------------------------------------------
          # NAME DETECTION (Tag → Instance → Definition)
          # --------------------------------------------------------
          tag_name = nil

          # Prefer Tag/Layer name
          if entity.respond_to?(:layer) && entity.layer
            tag_name = entity.layer.display_name
          end

          # Fallbacks
          if tag_name.nil? || tag_name.strip.empty?
            tag_name = entity.name
            if tag_name.empty? && entity.respond_to?(:definition)
              tag_name = entity.definition.name
            end
          end

          tag_name = "Unnamed" if tag_name.nil? || tag_name.strip.empty?

          # --------------------------------------------------------
          # EDGE BANDING DETECTION
          # Based on exact material names:
          #   Color A01 → Left
          #   Color A02 → Right
          #   Color A03 → Top
          #   Color A04 → Bottom
          # Multiple sides can be banded.
          # --------------------------------------------------------
          
          # Get all materials used on this object 
          materials = detect_all_materials(entity)
          
          eb_l = eb_r = eb_t = eb_b = ""

          materials.each do |mat|
            m = mat.strip.downcase

            eb_l = "x" if m == "color a01"
            eb_r = "x" if m == "color a02"
            eb_t = "x" if m == "color a03"
            eb_b = "x" if m == "color a04"
          end

          # --------------------------------------------------------
          # WRITE CSV ROW
          # --------------------------------------------------------
          file.write("#{tag_name},#{length},#{width},#{thickness},#{eb_l},#{eb_r},#{eb_t},#{eb_b}\n")
        end
      end

      UI.messagebox("element export complete!")
    end

    # ------------------------------------------------------------
    # Add menu item to SketchUp
    # ------------------------------------------------------------
    unless file_loaded?(__FILE__)
      UI.menu("Plugins").add_item(MENU_NAME) {
        self.export_csv
      }
      file_loaded(__FILE__)
    end

  end
end
