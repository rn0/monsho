Factory.define :user do |f|
  f.sequence(:email) { |n| "test#{n}@example.com" }
  f.password "foobar"
  f.password_confirmation { |u| u.password }
end