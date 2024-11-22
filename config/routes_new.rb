Rails.application.routes.draw do
  # Define the common routes that should be available at both root and /braintrap paths
  concern :braintrap_routes do
    get "feed/index"
    get "feed/line_annotation_xml"
    get "feed/annotations_xml"
    get "feed/full_xml"
    get "gene/index"
    get "gene/compare"
    get "gene/list"
    get "line/index"
    get "line/list"
    get "line/show"
    get "multibrain/index"
    get "search/index"
    get "search/interaction_search"
    get "search/ontology_match"
    get "search/search_form_free"
    get "search/search_form_gene"
    get "search/search_form"
    get "search/search_results_gene"
    get "search/search_results"
    get "search/viewer"
    get "stack/index"
    get "stack/list"
    get "stack/multistack"
    get "stack/show"
    get "tag/index"
    get "tag/list"
    get "tag/show"
    get "viewer/full"
    get "welcome/about"
    get "welcome/index"
    get "welcome/protocol"
  end

  # Health check route
  get "up" => "rails/health#show", as: :rails_health_check

  # Root path routes
  concerns :braintrap_routes
  root "welcome#index"

  # /braintrap path routes
  scope path: '/braintrap' do
    concerns :braintrap_routes
    # Use get instead of root to avoid naming conflict
    get '/', to: 'welcome#index', as: :braintrap_root
  end
end
