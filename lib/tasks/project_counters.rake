desc 'Update counter caches for projects'

namespace :counters do
  namespace :rebuild do
    task projects: :environment do
      Project.reset_column_information
      Project.pluck(:id).each do |id|
        Project.reset_counters id, :subject_reductions, :user_reductions
      end
    end
  end
end