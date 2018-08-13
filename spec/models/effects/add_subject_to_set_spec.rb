require 'spec_helper'

describe Effects::AddSubjectToSet do
  let(:workflow_id) { 10 }
  let(:subject_id){ 20 }
  let(:subject_set_id){ 1234 }

  let(:panoptes) { double("PanoptesAdapter", add_subjects_to_subject_set: true) }
  let(:effect) { described_class.new("subject_set_id" => subject_set_id) }

  before do
    allow(Effects).to receive(:panoptes).and_return(panoptes)
  end

  it 'adds the given subject to a given subject set' do
    effect.perform(workflow_id, subject_id)
    expect(panoptes).to have_received(:add_subjects_to_subject_set)
      .with(subject_set_id, [subject_id])
  end

  it 'knows when an exception is safe to ignore' do
    duplicate = { :errors => [{:message => "PG::UniqueViolation"}]}
    unexpected = { :errors => [{:message => "ActiveRecord::Error"}]}

    expect(described_class.was_duplicate(Panoptes::Client::ServerError.new(duplicate))).to be(true)
    expect(described_class.was_duplicate(Panoptes::Client::ServerError.new(unexpected))).to be(false)
  end

end
