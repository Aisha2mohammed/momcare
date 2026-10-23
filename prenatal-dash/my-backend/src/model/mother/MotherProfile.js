const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class MotherProfile extends Model {}

  MotherProfile.init({
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
    lmp_date: {
      type: DataTypes.DATEONLY
    },
    due_date: {
      type: DataTypes.DATEONLY
    },
    gestational_week: {
      type: DataTypes.INTEGER
    },
    city: {
      type: DataTypes.STRING(100)
    },
    profile_photo: {
      type: DataTypes.STRING(500)
    },
    assigned_doctor_id: {
      type: DataTypes.UUID
    }
  }, {
    sequelize,
    modelName: 'MotherProfile',
    tableName: 'mother_profiles',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
  });

  MotherProfile.associate = (models) => {
    MotherProfile.belongsTo(models.User, {
      foreignKey: 'user_id',
      as: 'user'
    });
    MotherProfile.belongsTo(models.User, {
      foreignKey: 'assigned_doctor_id',
      as: 'assignedDoctor'
    });
  };

  return MotherProfile;
};
