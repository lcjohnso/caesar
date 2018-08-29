desc 'Update counter caches for workflows'
namespace :counters do
  namespace :rebuild do
    task workflows: :environment do
      Workflow.reset_column_information
      Workflow.pluck(:id).each do |id|
        Workflow.reset_counters id, :extracts, :subject_reductions, :user_reductions, :subject_actions, :user_actions
      end
    end
  end
end