# ================================================================
#   element_export — SketchUp CSV Exporter
#   version: 1.0.3
#   Exports: label, thickness, length, width, pices, edge banding
#   Author: Sinisa (sinisak@live.com)
#
#   Features:
#   - Auto-detects dimensions (L/W/T)
#   - Detects materials from instance, definition, and faces
#   - Supports multi-side edge banding (A01/A02/A03/A04)
#   - Uses Tag/Layer name as part name
#   - Automatic counting of identical parts
#   - Sorting by deb (thickness) DESC -> length DESC -> width DESC
# ================================================================

require 'sketchup.rb'

module SinisaTools
  module ExportObject

    MENU_NAME = "element_export"

    # CSV header row
    CSV_HEADERS = "label,deb,length,width,pices,eb1,eb2,eb3,eb4\n"

    # ------------------------------------------------------------
    # Detect ALL materials used on the object:
    # 1. Instance material
    # 2. Definition material
    # 3. Face materials
    # ------------------------------------------------------------
    def self.detect_all_materials(entity)
      materials = []

      materials << entity.material if entity.material

      if entity.respond_to?(:definition) && entity.definition.material
        materials << entity.definition.material
      end

      if entity.respond_to?(:definition)
        entity.definition.entities.grep(Sketchup::Face).each do |face|
          materials << face.material if face.material
        end
      end

      materials.compact.map { |m| m.display_name.downcase }.uniq
    end

    # ------------------------------------------------------------
    # Main export function
    # ------------------------------------------------------------
    def self.export_csv
      model = Sketchup.active_model
      selection = model.selection

      if selection.empty?
        UI.messagebox("Please select at least one Group or Component.")
        return
      end

      filepath = UI.savepanel("Save element", "", "dimenzije.csv")
      return unless filepath

      # Hash for counting identical parts
      parts = Hash.new { |h, k| h[k] = { pices: 0 } }

      selection.each do |entity|
        next unless entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)

        # -------------------------
        # DIMENSIONS
        # -------------------------
        bbox = entity.bounds
        x = bbox.width.to_mm.round
        y = bbox.height.to_mm.round
        z = bbox.depth.to_mm.round

        dims = [x, y, z].sort
        thickness = dims[0]
        width     = dims[1]
        length    = dims[2]

        # -------------------------
        # NAME
        # -------------------------
        tag_name = if entity.respond_to?(:layer) && entity.layer
                     entity.layer.display_name
                   else
                     entity.name
                   end

        if tag_name.nil? || tag_name.strip.empty?
          tag_name = entity.respond_to?(:definition) ? entity.definition.name : "Unnamed"
        end

        tag_name = "Unnamed" if tag_name.nil? || tag_name.strip.empty?

        # -------------------------
        # EDGE BANDING
        # -------------------------
        materials = detect_all_materials(entity)

        eb1 = eb2 = eb3 = eb4 = ""

        materials.each do |mat|
          m = mat.strip.downcase
          eb1 = "x" if m == "color a01"
          eb2 = "x" if m == "color a02"
          eb3 = "x" if m == "color a03"
          eb4 = "x" if m == "color a04"
        end

        # -------------------------
        # UNIQUE KEY FOR COUNTING
        # -------------------------
        key = [
          tag_name,
          thickness,
          length,
          width,
          eb1, eb2, eb3, eb4
        ].join("|")

        # Store values + increment count
        parts[key][:name]      = tag_name
        parts[key][:thickness] = thickness
        parts[key][:length]    = length
        parts[key][:width]     = width
        parts[key][:eb1]       = eb1
        parts[key][:eb2]       = eb2
        parts[key][:eb3]       = eb3
        parts[key][:eb4]       = eb4
        parts[key][:pices]    += 1
      end

      # -------------------------
      # SORT PARTS
      # -------------------------
      sorted_parts = parts.values.sort_by { |p| [-p[:thickness], -p[:length], -p[:width]] }

      # -------------------------
      # WRITE CSV
      # -------------------------
      File.open(filepath, "w") do |file|
        file.write(CSV_HEADERS)

        sorted_parts.each do |p|
          file.write("#{p[:name]},#{p[:thickness]},#{p[:length]},#{p[:width]},#{p[:pices]},#{p[:eb1]},#{p[:eb2]},#{p[:eb3]},#{p[:eb4]}\n")
        end
      end

      UI.messagebox("element export complete!")
    end

    # ------------------------------------------------------------
    # Add menu item
    # ------------------------------------------------------------
    unless file_loaded?(__FILE__)
      UI.menu("Plugins").add_item(MENU_NAME) {
        self.export_csv
      }
      file_loaded(__FILE__)
    end

  end
end
