module TwoStep
  module ApplicationHelper
    def two_step_layout_title
      TwoStep.configuration.resolve_layout_title(controller: controller)
    end

    def two_step_layout_stylesheets
      TwoStep.configuration.resolve_layout_stylesheets(controller: controller)
    end

    def two_step_layout_html_attributes
      TwoStep.configuration.resolve_layout_html_attributes(controller: controller)
    end

    def two_step_layout_body_attributes
      TwoStep.configuration.resolve_layout_body_attributes(controller: controller)
    end

    def two_step_layout_brand
      TwoStep.configuration.resolve_layout_brand(controller: controller)
    end
  end
end
