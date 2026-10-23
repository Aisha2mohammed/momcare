const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class DoctorProfile extends Model {}

  DoctorProfile.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    user_id: {
      type: DataTypes.UUID,
      allowNull: false,
      unique: true
    },
    health_provider_id: {
      type: DataTypes.UUID
    },
    license_number: {
      type: DataTypes.STRING(100)
    },
    specialization: {
      type: DataTypes.STRING(255)
    },
    location: {
      type: DataTypes.STRING(500)
    },
    working_hours_json: {
      type: DataTypes.JSONB
    },
    credential_docs_json: {
      type: DataTypes.JSONB
    },
    approval_status: {
      type: DataTypes.STRING(20),
      defaultValue: 'pending'
    },
    approved_by: {
      type: DataTypes.UUID
    },
    approved_at: {
      type: DataTypes.DATE
    },
    photo_url: {
      type: DataTypes.STRING(500)
    },
    bio: {
      type: DataTypes.TEXT
    }
  }, {
    sequelize,
    modelName: 'DoctorProfile',
    tableName: 'doctor_profiles',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
  });

  DoctorProfile.associate = (models) => {
    DoctorProfile.belongsTo(models.User, {
      foreignKey: 'user_id',
      as: 'user'
    });
    DoctorProfile.belongsTo(models.HealthProvider, {
      foreignKey: 'health_provider_id',
      as: 'healthProvider'
    });
    DoctorProfile.belongsTo(models.User, {
      foreignKey: 'approved_by',
      as: 'approver'
    });
  };

  return DoctorProfile;
};
