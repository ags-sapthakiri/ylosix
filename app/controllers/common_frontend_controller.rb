class CommonFrontendController < ApplicationController
  before_action :set_common_variables
  before_action :set_query_text

  def get_template_variables(template)
    @variables['current_customer'] = current_customer
    @variables['new_customer_href'] = new_customer_session_path
    @variables['template_public_path'] = template.path.gsub('/public', '')

    @variables['search_url'] = Rails.application.routes.url_helpers.searches_path
    @variables['authenticity_token'] = form_authenticity_token
  end

  def self.static_set_common_variables
    variables = {}
    variables['languages'] = Language.in_frontend
    variables['categories'] = Category.root_categories
    variables['products'] = Product.all.limit(10) # TODO This only for test.

    variables
  end

  private

  def set_common_variables
    @variables = CommonFrontendController.static_set_common_variables
  end

  def set_query_text
    @query_text = ''
    @query_text = params[:query_text] unless params[:query_text].blank?
  end

  def replace_regex_include(template, content)
    regex_include_snippet = /{{\s*include\s+(?<file>[^}\s]+)\s*}}/

    match_data = regex_include_snippet.match(content)
    if match_data
      snippet_content = template.reads_file(match_data[:file])

      new_content = content.gsub(match_data.to_s, snippet_content)
      content = replace_regex_include(template, new_content)
    end

    regex_all_variables_public_path = /{{\s*all_variables\s*}}/
    match_data = regex_all_variables_public_path.match(content)
    if match_data
      content_hash_variables = Utils.pretty_json_template_variables(@variables)

      new_content = content.gsub(match_data.to_s, "<pre><code>#{JSON.pretty_generate(content_hash_variables)}</code></pre>")
      content = replace_regex_include(template, new_content)
    end

    content
  end

  def retrieve_html_template(template, template_liquid)
    @head_javascript = template.reads_file('common_js.js')
    @head_css = template.reads_file('common_css.css')

    @body_content = template_liquid.render(@variables)
  end

  def render(*args)
    template = Template.find_by(enabled: true)

    contains_template_layout = false
    unless args.empty?
      contains_template_layout = args.include?(layout: 'template_layout')
    end

    if !contains_template_layout && !template.nil? && template.ok?("#{controller_name}_#{action_name}.html")
      get_template_variables(template)

      body_code = template.reads_file("#{controller_name}_#{action_name}.html")
      body_code = replace_regex_include(template, body_code)

      # Parses and compiles the template
      template_liquid = Liquid::Template.parse(body_code)
      retrieve_html_template(template, template_liquid)

      render layout: 'template_layout'
    else
      super
    end
  end
end
